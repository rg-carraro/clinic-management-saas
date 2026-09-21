import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import UTC, datetime, timedelta

import pytest
from conftest import register
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import sessionmaker

from clinic.domain.models import Membership, Subscription
from clinic.domain.operations import Payment
from clinic.infrastructure.database import get_db
from clinic.presentation.api import app


def setup_clinic(client, suffix="a"):
    headers = register(client, suffix)
    patient = client.post(
        "/v1/patients", headers=headers, json={"name": "Patient Test", "phone": "5511999999999"}
    ).json()
    professional = client.post(
        "/v1/professionals", headers=headers, json={"name": "Professional Test"}
    ).json()
    service = client.post(
        "/v1/services", headers=headers, json={"name": "Atendimento", "default_price_cents": 15000}
    ).json()
    start = datetime.now(UTC).replace(microsecond=0) + timedelta(days=1)
    appointment_body = {
        "patient_id": patient["id"],
        "professional_id": professional["id"],
        "service_id": service["id"],
        "starts_at": start.isoformat(),
        "ends_at": (start + timedelta(hours=1)).isoformat(),
    }
    return headers, patient, professional, service, appointment_body


def attendance(client, headers, body):
    scheduled = client.post("/v1/appointments", headers=headers, json=body)
    assert scheduled.status_code == 201, scheduled.text
    done = client.post(
        f"/v1/appointments/{scheduled.json()['id']}/complete", headers=headers, json={}
    )
    assert done.status_code == 201, done.text
    return scheduled.json(), done.json()


def payment(client, headers, record, cents, key=None):
    return client.post(
        "/v1/payments",
        headers={**headers, "Idempotency-Key": key or str(uuid.uuid4())},
        json={"attendance_id": record["id"], "amount_cents": cents, "method": "PIX"},
    )


def test_partial_total_historical_price_and_whatsapp(client):
    h, patient, _, service, body = setup_clinic(client)
    scheduled, record = attendance(client, h, body)
    assert (
        client.patch(
            f"/v1/services/{service['id']}",
            headers=h,
            json={"name": "Novo serviço", "default_price_cents": 30000},
        ).status_code
        == 200
    )
    assert payment(client, h, record, 5000).status_code == 201
    balance = client.get(f"/v1/patients/{patient['id']}/balance", headers=h).json()
    assert balance == {"charged_cents": 15000, "paid_cents": 5000, "balance_cents": 10000}
    message = client.get(f"/v1/patients/{patient['id']}/whatsapp", headers=h).json()
    assert "100,00" in message["message"]
    assert "Patient" not in message["message"] and "Atendimento" not in message["message"]
    assert payment(client, h, record, 10000).status_code == 201
    assert payment(client, h, record, 1).status_code == 409
    stored = client.get("/v1/attendances", headers=h).json()[0]
    assert stored["service_name"] == "Atendimento"
    assert stored["balance_cents"] == 0
    assert (
        client.post(f"/v1/appointments/{scheduled['id']}/complete", headers=h, json={}).json()["id"]
        == record["id"]
    )
    assert len(client.get("/v1/attendances", headers=h).json()) == 1


def test_idempotent_payments_and_reused_key_conflict(client, database):
    h, _, _, _, body = setup_clinic(client)
    _, record = attendance(client, h, body)
    key = str(uuid.uuid4())
    first = payment(client, h, record, 4000, key)
    assert first.status_code == 201
    assert payment(client, h, record, 4000, key).json() == first.json()
    assert payment(client, h, record, 5000, key).status_code == 409
    assert len(list(database.scalars(select(Payment)))) == 1
    assert payment(client, h, record, -1).status_code == 422
    assert payment(client, h, record, 1.5).status_code == 422


def test_cross_tenant_reads_writes_and_foreign_keys(client):
    a, pa, _, _, body_a = setup_clinic(client)
    b, pb, _, _, body_b = setup_clinic(client, "b")
    appointment_b, record_b = attendance(client, b, body_b)
    assert client.get(f"/v1/patients/{pb['id']}/balance", headers=a).status_code == 404
    assert (
        client.patch(f"/v1/patients/{pb['id']}", headers=a, json={"name": "Changed"}).status_code
        == 404
    )
    assert (
        client.post(
            "/v1/appointments", headers=a, json={**body_a, "patient_id": pb["id"]}
        ).status_code
        == 404
    )
    assert (
        client.post(
            f"/v1/appointments/{appointment_b['id']}/complete", headers=a, json={}
        ).status_code
        == 404
    )
    assert payment(client, a, record_b, 100).status_code == 404
    assert (
        client.get("/v1/payments", headers=a, params={"attendance_id": record_b["id"]}).status_code
        == 404
    )
    assert client.get(f"/v1/patients/{pb['id']}/whatsapp", headers=a).status_code == 404
    assert client.get("/v1/dashboard", headers=a).json()["charged_cents"] == 0
    assert client.get("/v1/patients", headers=a).json()[0]["id"] == pa["id"]


def test_staff_cannot_complete_and_professional_owns_agenda(client, database):
    h, _, _, _, body = setup_clinic(client)
    subscription = database.get(Subscription, h["X-Tenant-ID"])
    subscription.tier = "PRO"
    staff = register(client, "staff")
    assert (
        client.post(
            "/v1/members", headers=h, json={"email": "ownerstaff@example.com", "role": "STAFF"}
        ).status_code
        == 201
    )
    staff["X-Tenant-ID"] = h["X-Tenant-ID"]
    scheduled = client.post("/v1/appointments", headers=staff, json=body)
    assert scheduled.status_code == 201
    path = f"/v1/appointments/{scheduled.json()['id']}/complete"
    assert client.post(path, headers=staff, json={}).status_code == 403
    member = database.scalar(
        select(Membership).where(
            Membership.organization_id == h["X-Tenant-ID"], Membership.role == "STAFF"
        )
    )
    member.role = "PROFESSIONAL"
    database.commit()
    assert client.post(path, headers=staff, json={}).status_code == 403
    assert client.post(path, headers=h, json={}).status_code == 201


def test_overlap_cancel_reschedule_and_archive(client):
    h, patient, _, _, body = setup_clinic(client)
    first = client.post("/v1/appointments", headers=h, json=body).json()
    assert client.post("/v1/appointments", headers=h, json=body).status_code == 409
    assert client.post(f"/v1/appointments/{first['id']}/cancel", headers=h).status_code == 204
    assert (
        client.post(f"/v1/appointments/{first['id']}/complete", headers=h, json={}).status_code
        == 409
    )
    second = client.post("/v1/appointments", headers=h, json=body)
    assert second.status_code == 201
    assert (
        client.patch(
            f"/v1/patients/{patient['id']}",
            headers=h,
            json={"name": patient["name"], "active": False},
        ).status_code
        == 200
    )
    assert client.post("/v1/appointments", headers=h, json=body).status_code == 400
    assert (
        client.post(
            "/v1/patients", headers=h, json={"name": "Example", "diagnosis": "forbidden"}
        ).status_code
        == 422
    )


def test_trial_and_feature_flags_block_backend(client, database, monkeypatch):
    h, _, _, _, body = setup_clinic(client)
    from clinic.shared.config import get_settings

    monkeypatch.setattr(get_settings(), "disabled_features", ["patients"])
    assert client.get("/v1/patients", headers=h).status_code == 403
    monkeypatch.setattr(get_settings(), "disabled_features", [])
    subscription = database.get(Subscription, h["X-Tenant-ID"])
    subscription.trial_ends_at = 1
    database.commit()
    for path in [
        "/patients",
        "/services",
        "/professionals",
        "/appointments",
        "/attendances",
        "/dashboard",
    ]:
        assert client.get("/v1" + path, headers=h).status_code == 403
    assert client.post("/v1/appointments", headers=h, json=body).status_code == 403


def test_report_date_semantics_and_csv(client):
    h, _, _, _, body = setup_clinic(client)
    _, record = attendance(client, h, body)
    payment(client, h, record, 3500)
    start = int(datetime.now(UTC).timestamp()) - 100
    params = {"start": start, "end": start + 3 * 86400}
    report = client.get("/v1/reports/summary", headers=h, params=params).json()
    assert report["charged_cents"] == 15000
    assert report["received_cents"] == 3500
    assert report["outstanding_total_cents"] == 11500
    exported = client.get("/v1/reports/summary", headers=h, params={**params, "format": "csv"})
    assert exported.status_code == 200
    assert "15000,3500,11500" in exported.text
    assert (
        client.get("/v1/reports/summary", headers=h, params={"start": 1, "end": 1}).status_code
        == 422
    )


@pytest.mark.parametrize("same_key", [False, True])
def test_concurrent_payments_cannot_overpay_postgres(client, database, same_key):
    if database.bind.dialect.name != "postgresql":
        pytest.skip("PostgreSQL concurrency gate runs in CI")
    h, _, _, _, body = setup_clinic(client)
    _, record = attendance(client, h, body)
    factory = sessionmaker(database.bind, expire_on_commit=False)

    def independent_db():
        with factory() as session:
            yield session

    app.dependency_overrides[get_db] = independent_db

    operation_key = str(uuid.uuid4()) if same_key else None

    def send(_):
        with TestClient(app) as independent_client:
            return payment(independent_client, h, record, 10000, operation_key).status_code

    with ThreadPoolExecutor(max_workers=2) as executor:
        results = list(executor.map(send, range(2)))
    assert sorted(results) == ([201, 201] if same_key else [201, 409])
    database.expire_all()
    assert sum(p.amount_cents for p in database.scalars(select(Payment))) == 10000
