from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    ForeignKey,
    ForeignKeyConstraint,
    Integer,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from clinic.domain.models import new_id
from clinic.infrastructure.database import Base


class TenantRecord:
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    organization_id: Mapped[str] = mapped_column(ForeignKey("organizations.id"), index=True)


class Patient(TenantRecord, Base):
    __tablename__ = "patients"
    __table_args__ = (UniqueConstraint("organization_id", "id"),)
    name: Mapped[str] = mapped_column(String(120))
    phone: Mapped[str] = mapped_column(String(16), default="")
    email: Mapped[str] = mapped_column(String(254), default="")
    active: Mapped[bool] = mapped_column(Boolean, default=True)


class Professional(TenantRecord, Base):
    __tablename__ = "professionals"
    __table_args__ = (
        UniqueConstraint("organization_id", "id"),
        UniqueConstraint("organization_id", "user_id"),
    )
    name: Mapped[str] = mapped_column(String(120))
    user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"))
    active: Mapped[bool] = mapped_column(Boolean, default=True)


class Service(TenantRecord, Base):
    __tablename__ = "services"
    __table_args__ = (
        UniqueConstraint("organization_id", "id"),
        CheckConstraint("default_price_cents >= 0"),
    )
    name: Mapped[str] = mapped_column(String(120))
    default_price_cents: Mapped[int] = mapped_column(Integer)
    active: Mapped[bool] = mapped_column(Boolean, default=True)


class Appointment(TenantRecord, Base):
    __tablename__ = "appointments"
    __table_args__ = (
        UniqueConstraint("organization_id", "id"),
        ForeignKeyConstraint(
            ["organization_id", "patient_id"], ["patients.organization_id", "patients.id"]
        ),
        ForeignKeyConstraint(
            ["organization_id", "professional_id"],
            ["professionals.organization_id", "professionals.id"],
        ),
        ForeignKeyConstraint(
            ["organization_id", "service_id"], ["services.organization_id", "services.id"]
        ),
        CheckConstraint("ends_at > starts_at"),
        CheckConstraint("price_cents >= 0"),
        CheckConstraint("status IN ('SCHEDULED','COMPLETED','CANCELED')"),
    )
    patient_id: Mapped[str] = mapped_column(String(36), index=True)
    professional_id: Mapped[str] = mapped_column(String(36), index=True)
    service_id: Mapped[str] = mapped_column(String(36))
    starts_at: Mapped[int] = mapped_column(BigInteger, index=True)
    ends_at: Mapped[int] = mapped_column(BigInteger)
    price_cents: Mapped[int] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(20), default="SCHEDULED")


class Attendance(TenantRecord, Base):
    __tablename__ = "attendances"
    __table_args__ = (
        UniqueConstraint("organization_id", "id"),
        UniqueConstraint("organization_id", "appointment_id"),
        ForeignKeyConstraint(
            ["organization_id", "appointment_id"],
            ["appointments.organization_id", "appointments.id"],
        ),
        ForeignKeyConstraint(
            ["organization_id", "patient_id"], ["patients.organization_id", "patients.id"]
        ),
        ForeignKeyConstraint(
            ["organization_id", "professional_id"],
            ["professionals.organization_id", "professionals.id"],
        ),
        CheckConstraint("price_cents >= 0"),
    )
    appointment_id: Mapped[str] = mapped_column(String(36))
    patient_id: Mapped[str] = mapped_column(String(36), index=True)
    professional_id: Mapped[str] = mapped_column(String(36))
    service_name: Mapped[str] = mapped_column(String(120))
    price_cents: Mapped[int] = mapped_column(Integer)
    occurred_at: Mapped[int] = mapped_column(BigInteger, index=True)


class Payment(TenantRecord, Base):
    __tablename__ = "payments"
    __table_args__ = (
        UniqueConstraint("organization_id", "idempotency_key"),
        ForeignKeyConstraint(
            ["organization_id", "attendance_id"], ["attendances.organization_id", "attendances.id"]
        ),
        CheckConstraint("amount_cents > 0"),
        CheckConstraint("method IN ('PIX','CASH','CARD','TRANSFER')"),
    )
    attendance_id: Mapped[str] = mapped_column(String(36), index=True)
    amount_cents: Mapped[int] = mapped_column(Integer)
    method: Mapped[str] = mapped_column(String(20))
    received_at: Mapped[int] = mapped_column(BigInteger, index=True)
    idempotency_key: Mapped[str] = mapped_column(String(80))
