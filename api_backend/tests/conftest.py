import os

os.environ.setdefault("APP_ENV", "test")

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import sessionmaker

from clinic.infrastructure.database import Base, get_db, make_engine
from clinic.presentation.api import app


@pytest.fixture
def database(tmp_path):
    url = os.environ.get("TEST_DATABASE_URL")
    if url and not url.rsplit("/", 1)[-1].endswith("_test"):
        raise RuntimeError("Tests require a dedicated database ending in _test")
    engine = make_engine(url or f"sqlite:///{tmp_path / 'test.db'}")
    Base.metadata.create_all(engine)
    factory = sessionmaker(engine, expire_on_commit=False)
    with factory() as db:
        yield db
    Base.metadata.drop_all(engine)
    engine.dispose()


@pytest.fixture
def client(database):
    def override():
        yield database

    app.dependency_overrides[get_db] = override
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


def register(client, suffix="a"):
    response = client.post(
        "/v1/auth/register",
        json={
            "email": f"owner{suffix}@example.com",
            "password": "Strong-test-password-123",
            "name": "Owner Test",
            "organization_name": f"Clinic {suffix}",
        },
    )
    assert response.status_code == 201, response.text
    data = response.json()
    return {
        "Authorization": "Bearer " + data["access_token"],
        "X-Tenant-ID": data["organizations"][0]["id"],
    }
