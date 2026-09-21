import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from clinic.presentation.api import app
from clinic.shared.config import Settings


def test_health_and_no_cache():
    response = TestClient(app).get("/health")
    assert response.json() == {"status": "ok"}
    assert response.headers["cache-control"] == "no-store"


def test_production_rejects_local_defaults():
    with pytest.raises(ValidationError):
        Settings(app_env="prod", _env_file=None)
