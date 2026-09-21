from conftest import register
from sqlalchemy import select

from clinic.domain.models import PasswordReset, Session, Subscription
from clinic.infrastructure.security import now, token_hash


def test_registration_isolation_and_logout(client):
    a, b = register(client), register(client, "b")
    assert client.get("/v1/me").status_code == 401
    me = client.get("/v1/me", headers=a).json()
    assert me["role"] == "OWNER"
    assert 604790 <= me["subscription"]["trial_ends_at"] - now() <= 604800
    assert "patients" in me["entitlements"]
    assert client.get("/v1/me", headers={**a, "X-Tenant-ID": b["X-Tenant-ID"]}).status_code == 403
    assert client.post("/v1/auth/logout", headers=a).status_code == 204
    assert client.get("/v1/me", headers=a).status_code == 401


def test_trial_persists_and_founder_never_expires(client, database):
    headers = register(client)
    subscription = database.get(Subscription, headers["X-Tenant-ID"])
    subscription.trial_ends_at = now() - 1
    database.commit()
    response = client.post(
        "/v1/auth/login",
        json={"email": "ownera@example.com", "password": "Strong-test-password-123"},
    )
    headers["Authorization"] = "Bearer " + response.json()["access_token"]
    assert client.get("/v1/me", headers=headers).json()["entitlements"] == []
    assert client.get("/v1/members", headers=headers).status_code == 403
    subscription.license = "FOUNDER"
    database.commit()
    assert "patients" in client.get("/v1/me", headers=headers).json()["entitlements"]
    assert client.get("/v1/members", headers=headers).status_code == 403
    subscription.tier = "PRO"
    database.commit()
    assert client.get("/v1/members", headers=headers).status_code == 200


def test_reset_single_use_revokes_sessions_and_does_not_leak(client, database, monkeypatch):
    headers = register(client)
    sent = []
    monkeypatch.setattr(
        "clinic.presentation.auth_routes.send_reset", lambda email, token: sent.append(token)
    )
    known = client.post("/v1/auth/password/forgot", json={"email": "ownera@example.com"})
    unknown = client.post("/v1/auth/password/forgot", json={"email": "absent@example.com"})
    assert known.json() == unknown.json()
    assert len(sent) == 1
    record = database.scalar(select(PasswordReset))
    assert record.token_hash == token_hash(sent[0])
    body = {"token": sent[0], "password": "New-strong-password-456"}
    assert client.post("/v1/auth/password/reset", json=body).status_code == 204
    assert client.post("/v1/auth/password/reset", json=body).status_code == 400
    assert client.get("/v1/me", headers=headers).status_code == 401
    assert (
        client.post(
            "/v1/auth/login", json={"email": "ownera@example.com", "password": body["password"]}
        ).status_code
        == 200
    )


def test_no_client_entitlement_promotion_and_role_control(client, database):
    a, b = register(client), register(client, "b")
    assert (
        client.post(
            "/v1/members", headers=a, json={"email": "ownerb@example.com", "role": "ADMIN"}
        ).status_code
        == 403
    )
    subscription = database.get(Subscription, a["X-Tenant-ID"])
    subscription.tier = "PRO"
    database.commit()
    assert (
        client.post(
            "/v1/members", headers=a, json={"email": "ownerb@example.com", "role": "OWNER"}
        ).status_code
        == 422
    )
    added = client.post(
        "/v1/members", headers=a, json={"email": "ownerb@example.com", "role": "STAFF"}
    )
    assert added.status_code == 201
    staff = {**b, "X-Tenant-ID": a["X-Tenant-ID"]}
    assert client.get("/v1/members", headers=staff).status_code == 403
    assert (
        client.post("/v1/members/" + added.json()["id"] + "/deactivate", headers=a).status_code
        == 204
    )
    assert client.get("/v1/me", headers=staff).status_code == 403


def test_expired_session_and_generic_login(client, database):
    headers = register(client)
    session = database.get(Session, token_hash(headers["Authorization"].split()[1]))
    session.expires_at = now() - 1
    database.commit()
    assert client.get("/v1/me", headers=headers).status_code == 401
    body = {"email": "absent@example.com", "password": "Incorrect-password-123"}
    unknown = client.post("/v1/auth/login", json=body)
    body["email"] = "ownera@example.com"
    known = client.post("/v1/auth/login", json=body)
    assert known.status_code == unknown.status_code == 401
    assert known.json() == unknown.json()


def test_rate_limit(client):
    for _ in range(12):
        client.post(
            "/v1/auth/login",
            json={"email": "missing@example.com", "password": "Not-a-valid-password"},
        )
    assert (
        client.post(
            "/v1/auth/login",
            json={"email": "missing@example.com", "password": "Not-a-valid-password"},
        ).status_code
        == 429
    )


def test_registration_rejects_commercial_fields(client):
    response = client.post(
        "/v1/auth/register",
        json={
            "email": "x@example.com",
            "password": "Strong-test-password-123",
            "name": "User",
            "organization_name": "Clinic",
            "license": "FOUNDER",
        },
    )
    assert response.status_code == 422
