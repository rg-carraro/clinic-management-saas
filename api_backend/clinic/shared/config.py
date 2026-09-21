from functools import lru_cache
from typing import Literal

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    app_env: Literal["dev", "staging", "prod", "test"] = "dev"
    database_url: str = "sqlite:///./clinic.db"
    cors_origins: list[str] = ["http://localhost:8080"]
    public_app_url: str = "http://localhost:8080"
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_from: str = ""
    session_hours: int = 12
    disabled_features: list[str] = []

    @model_validator(mode="after")
    def deployment_rules(self):
        if self.app_env in {"staging", "prod"}:
            if not self.database_url.startswith("postgresql+psycopg://"):
                raise ValueError("PostgreSQL required for deployed environments")
            if not self.public_app_url.startswith("https://"):
                raise ValueError("HTTPS public_app_url required")
            if not self.smtp_host or not self.smtp_from:
                raise ValueError("SMTP configuration required")
            if not self.cors_origins or any(
                not x.startswith("https://") for x in self.cors_origins
            ):
                raise ValueError("Explicit HTTPS CORS origins required")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()
