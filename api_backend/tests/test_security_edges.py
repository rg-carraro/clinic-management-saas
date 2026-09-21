import pytest
from conftest import register
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from test_operations import setup_clinic

from clinic.domain.models import AuditEvent
from clinic.domain.operations import Appointment


def test_database_rejects_cross_tenant_foreign_key(client, database):
    a, _, professional, service, _ = setup_clinic(client)
    _, foreign_patient, _, _, _ = setup_clinic(client, "other")
    database.add(
        Appointment(
            organization_id=a["X-Tenant-ID"],
            patient_id=foreign_patient["id"],
            professional_id=professional["id"],
            service_id=service["id"],
            starts_at=1800000000,
            ends_at=1800003600,
            price_cents=10000,
        )
    )
    with pytest.raises(IntegrityError):
        database.flush()
    database.rollback()


def test_validation_and_audit_do_not_contain_sensitive_input(client, database):
    headers = register(client)
    secret = "Never-echo-this-password"
    response = client.post("/v1/auth/login", json={"email": "invalid", "password": secret})
    assert response.status_code == 422
    assert secret not in response.text and "invalid" not in response.text
    result = client.post("/v1/patients", headers=headers, json={"name": "Private Patient Name"})
    assert result.status_code == 201
    events = list(database.scalars(select(AuditEvent)))
    assert all("Private" not in event.action for event in events)
    assert any(event.target_id == result.json()["id"] for event in events)


def test_essential_cannot_add_multiple_agendas(client):
    headers, _, _, _, _ = setup_clinic(client)
    assert (
        client.post(
            "/v1/professionals", headers=headers, json={"name": "Second agenda"}
        ).status_code
        == 403
    )
