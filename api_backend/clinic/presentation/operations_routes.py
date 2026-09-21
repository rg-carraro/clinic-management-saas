import csv
import io
from typing import Annotated, Literal
from urllib.parse import quote

from fastapi import APIRouter, Depends, Header, HTTPException, Query
from fastapi.responses import Response
from pydantic import AwareDatetime, EmailStr, Field, model_validator
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session as DbSession

from clinic.application.auth import TenantContext, audit, require
from clinic.application.operations import balance_for, paid_for, scoped
from clinic.domain.models import Membership, Organization
from clinic.domain.operations import (
    Appointment,
    Attendance,
    Patient,
    Payment,
    Professional,
    Service,
)
from clinic.infrastructure.database import get_db
from clinic.infrastructure.security import now
from clinic.presentation.auth_routes import Input

router = APIRouter(prefix="/v1", tags=["operations"])
Cents = Annotated[int, Field(strict=True, ge=0, le=100_000_000)]


class PatientInput(Input):
    name: str = Field(min_length=2, max_length=120)
    phone: str = Field(default="", pattern=r"^([1-9][0-9]{9,14})?$")
    email: EmailStr | Literal[""] = ""
    active: bool = True


class ServiceInput(Input):
    name: str = Field(min_length=2, max_length=120)
    default_price_cents: Cents
    active: bool = True


class ProfessionalInput(Input):
    name: str = Field(min_length=2, max_length=120)
    user_id: str | None = None


class AppointmentInput(Input):
    patient_id: str
    professional_id: str
    service_id: str
    starts_at: AwareDatetime
    ends_at: AwareDatetime
    price_cents: Cents | None = None

    @model_validator(mode="after")
    def valid_period(self):
        if (
            self.ends_at <= self.starts_at
            or (self.ends_at - self.starts_at).total_seconds() > 86400
        ):
            raise ValueError("Horário final deve ser posterior ao início, em até 24 horas")
        return self


class CompleteInput(Input):
    price_cents: Cents | None = None


class PaymentInput(Input):
    attendance_id: str
    amount_cents: Annotated[int, Field(strict=True, gt=0, le=100_000_000)]
    method: Literal["PIX", "CASH", "CARD", "TRANSFER"]


def row(record, fields):
    return {key: getattr(record, key) for key in ["id", *fields]}


def patient_out(record):
    return row(record, ["name", "phone", "email", "active"])


def attendance_out(db, tenant, record):
    result = row(
        record,
        [
            "appointment_id",
            "patient_id",
            "professional_id",
            "service_name",
            "price_cents",
            "occurred_at",
        ],
    )
    result["patient_name"] = scoped(db, Patient, tenant, record.patient_id).name
    result["paid_cents"] = paid_for(db, tenant, record.id)
    result["balance_cents"] = record.price_cents - result["paid_cents"]
    return result


def payment_out(record):
    return row(record, ["attendance_id", "amount_cents", "method", "received_at"])


@router.get("/patients")
def patients(
    q: str = Query("", max_length=120),
    limit: int = Query(100, ge=1, le=100),
    offset: int = Query(0, ge=0),
    context: TenantContext = Depends(require("patients")),
    db: DbSession = Depends(get_db),
):
    query = select(Patient).where(Patient.organization_id == context.tenant_id)
    if q:
        query = query.where(Patient.name.icontains(q, autoescape=True))
    return [
        patient_out(p)
        for p in db.scalars(query.order_by(Patient.name, Patient.id).limit(limit).offset(offset))
    ]


@router.post("/patients", status_code=201)
def create_patient(
    body: PatientInput,
    context: TenantContext = Depends(require("patients", "patients.write")),
    db: DbSession = Depends(get_db),
):
    patient = Patient(organization_id=context.tenant_id, **body.model_dump())
    db.add(patient)
    db.flush()
    audit(db, context.user.id, context.tenant_id, "patient.created", patient.id)
    db.commit()
    return patient_out(patient)


@router.patch("/patients/{patient_id}")
def edit_patient(
    patient_id: str,
    body: PatientInput,
    context: TenantContext = Depends(require("patients", "patients.write")),
    db: DbSession = Depends(get_db),
):
    patient = scoped(db, Patient, context.tenant_id, patient_id, lock=True)
    for key, value in body.model_dump().items():
        setattr(patient, key, value)
    audit(db, context.user.id, context.tenant_id, "patient.updated", patient.id)
    db.commit()
    return patient_out(patient)


@router.get("/patients/{patient_id}/balance")
def patient_balance(
    patient_id: str,
    context: TenantContext = Depends(require("finance")),
    db: DbSession = Depends(get_db),
):
    scoped(db, Patient, context.tenant_id, patient_id)
    return balance_for(db, context.tenant_id, patient_id)


@router.get("/services")
def services(context: TenantContext = Depends(require("agenda")), db: DbSession = Depends(get_db)):
    return [
        row(s, ["name", "default_price_cents", "active"])
        for s in db.scalars(
            select(Service)
            .where(Service.organization_id == context.tenant_id)
            .order_by(Service.name, Service.id)
        )
    ]


@router.post("/services", status_code=201)
def create_service(
    body: ServiceInput,
    context: TenantContext = Depends(require("agenda", "catalog.write")),
    db: DbSession = Depends(get_db),
):
    service = Service(organization_id=context.tenant_id, **body.model_dump())
    db.add(service)
    db.flush()
    audit(db, context.user.id, context.tenant_id, "service.created", service.id)
    db.commit()
    return row(service, ["name", "default_price_cents", "active"])


@router.patch("/services/{service_id}")
def edit_service(
    service_id: str,
    body: ServiceInput,
    context: TenantContext = Depends(require("agenda", "catalog.write")),
    db: DbSession = Depends(get_db),
):
    service = scoped(db, Service, context.tenant_id, service_id, lock=True)
    for key, value in body.model_dump().items():
        setattr(service, key, value)
    audit(db, context.user.id, context.tenant_id, "service.updated", service.id)
    db.commit()
    return row(service, ["name", "default_price_cents", "active"])


@router.get("/professionals")
def professionals(
    context: TenantContext = Depends(require("agenda")), db: DbSession = Depends(get_db)
):
    return [
        row(p, ["name", "user_id", "active"])
        for p in db.scalars(
            select(Professional)
            .where(Professional.organization_id == context.tenant_id)
            .order_by(Professional.name, Professional.id)
        )
    ]


@router.post("/professionals", status_code=201)
def create_professional(
    body: ProfessionalInput,
    context: TenantContext = Depends(require("agenda", "catalog.write")),
    db: DbSession = Depends(get_db),
):
    # Lock the organization so simultaneous requests cannot bypass Essential's single agenda.
    if db.bind.dialect.name == "sqlite":
        from sqlalchemy import update

        db.execute(
            update(Organization)
            .where(Organization.id == context.tenant_id)
            .values(name=Organization.name)
        )
    db.scalar(select(Organization).where(Organization.id == context.tenant_id).with_for_update())
    count = db.scalar(
        select(func.count())
        .select_from(Professional)
        .where(Professional.organization_id == context.tenant_id)
    )
    if count and "team" not in context.features:
        raise HTTPException(403, "Múltiplas agendas requerem Pro")
    user_id = body.user_id or context.user.id
    member = db.scalar(
        select(Membership).where(
            Membership.organization_id == context.tenant_id,
            Membership.user_id == user_id,
            Membership.active.is_(True),
        )
    )
    if not member or member.role == "STAFF":
        raise HTTPException(400, "Profissional deve ter vínculo ativo e papel compatível")
    professional = Professional(organization_id=context.tenant_id, name=body.name, user_id=user_id)
    db.add(professional)
    try:
        db.flush()
        audit(db, context.user.id, context.tenant_id, "professional.created", professional.id)
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Usuário já possui agenda") from None
    return row(professional, ["name", "user_id", "active"])


def appointment_out(db, tenant, item):
    result = row(
        item,
        [
            "patient_id",
            "professional_id",
            "service_id",
            "starts_at",
            "ends_at",
            "price_cents",
            "status",
        ],
    )
    result["patient_name"] = scoped(db, Patient, tenant, item.patient_id).name
    result["professional_name"] = scoped(db, Professional, tenant, item.professional_id).name
    result["service_name"] = scoped(db, Service, tenant, item.service_id).name
    return result


def professional_permission(context, professional):
    if context.role == "PROFESSIONAL" and professional.user_id != context.user.id:
        raise HTTPException(403, "Profissional pode alterar apenas sua própria agenda")


def schedule(db, context, body, current=None):
    patient = scoped(db, Patient, context.tenant_id, body.patient_id)
    service = scoped(db, Service, context.tenant_id, body.service_id)
    professional = scoped(db, Professional, context.tenant_id, body.professional_id, lock=True)
    professional_permission(context, professional)
    if not patient.active or not service.active or not professional.active:
        raise HTTPException(400, "Use cadastros ativos")
    start, end = int(body.starts_at.timestamp()), int(body.ends_at.timestamp())
    query = select(Appointment).where(
        Appointment.organization_id == context.tenant_id,
        Appointment.professional_id == professional.id,
        Appointment.status != "CANCELED",
        Appointment.starts_at < end,
        Appointment.ends_at > start,
    )
    if current:
        query = query.where(Appointment.id != current.id)
    if db.scalar(query):
        raise HTTPException(409, "Horário já ocupado nesta agenda")
    data = {
        "patient_id": patient.id,
        "professional_id": professional.id,
        "service_id": service.id,
        "starts_at": start,
        "ends_at": end,
        "price_cents": body.price_cents
        if body.price_cents is not None
        else (current.price_cents if current else service.default_price_cents),
    }
    if current:
        for key, value in data.items():
            setattr(current, key, value)
        return current
    result = Appointment(organization_id=context.tenant_id, **data)
    db.add(result)
    return result


@router.get("/appointments")
def appointments(
    start: int | None = None,
    end: int | None = None,
    limit: int = Query(100, ge=1, le=100),
    offset: int = Query(0, ge=0),
    context: TenantContext = Depends(require("agenda")),
    db: DbSession = Depends(get_db),
):
    query = select(Appointment).where(Appointment.organization_id == context.tenant_id)
    if start is not None:
        query = query.where(Appointment.starts_at >= start)
    if end is not None:
        query = query.where(Appointment.starts_at < end)
    return [
        appointment_out(db, context.tenant_id, a)
        for a in db.scalars(
            query.order_by(Appointment.starts_at, Appointment.id).limit(limit).offset(offset)
        )
    ]


@router.post("/appointments", status_code=201)
def create_appointment(
    body: AppointmentInput,
    context: TenantContext = Depends(require("agenda", "agenda.write")),
    db: DbSession = Depends(get_db),
):
    item = schedule(db, context, body)
    db.flush()
    audit(db, context.user.id, context.tenant_id, "appointment.created", item.id)
    db.commit()
    return appointment_out(db, context.tenant_id, item)


@router.patch("/appointments/{appointment_id}")
def edit_appointment(
    appointment_id: str,
    body: AppointmentInput,
    context: TenantContext = Depends(require("agenda", "agenda.write")),
    db: DbSession = Depends(get_db),
):
    item = scoped(db, Appointment, context.tenant_id, appointment_id, lock=True)
    professional_permission(
        context, scoped(db, Professional, context.tenant_id, item.professional_id)
    )
    if item.status != "SCHEDULED":
        raise HTTPException(409, "Somente agendamentos pendentes podem ser alterados")
    schedule(db, context, body, item)
    audit(db, context.user.id, context.tenant_id, "appointment.updated", item.id)
    db.commit()
    return appointment_out(db, context.tenant_id, item)


@router.post("/appointments/{appointment_id}/cancel", status_code=204)
def cancel(
    appointment_id: str,
    context: TenantContext = Depends(require("agenda", "agenda.write")),
    db: DbSession = Depends(get_db),
):
    item = scoped(db, Appointment, context.tenant_id, appointment_id, lock=True)
    professional_permission(
        context, scoped(db, Professional, context.tenant_id, item.professional_id)
    )
    if item.status == "COMPLETED":
        raise HTTPException(409, "Atendimento concluído não pode ser cancelado")
    item.status = "CANCELED"
    audit(db, context.user.id, context.tenant_id, "appointment.canceled", item.id)
    db.commit()


@router.post("/appointments/{appointment_id}/complete", status_code=201)
def complete(
    appointment_id: str,
    body: CompleteInput,
    context: TenantContext = Depends(require("attendances", "attendance.write")),
    db: DbSession = Depends(get_db),
):
    item = scoped(db, Appointment, context.tenant_id, appointment_id, lock=True)
    professional_permission(
        context, scoped(db, Professional, context.tenant_id, item.professional_id)
    )
    if item.status == "CANCELED":
        raise HTTPException(409, "Agendamento cancelado")
    existing = db.scalar(
        select(Attendance).where(
            Attendance.organization_id == context.tenant_id, Attendance.appointment_id == item.id
        )
    )
    if existing:
        if body.price_cents is not None and body.price_cents != existing.price_cents:
            raise HTTPException(409, "Atendimento já concluído com outro valor")
        return attendance_out(db, context.tenant_id, existing)
    service = scoped(db, Service, context.tenant_id, item.service_id)
    record = Attendance(
        organization_id=context.tenant_id,
        appointment_id=item.id,
        patient_id=item.patient_id,
        professional_id=item.professional_id,
        service_name=service.name,
        price_cents=body.price_cents if body.price_cents is not None else item.price_cents,
        occurred_at=item.starts_at,
    )
    db.add(record)
    item.status = "COMPLETED"
    db.flush()
    audit(db, context.user.id, context.tenant_id, "attendance.created", record.id)
    db.commit()
    return attendance_out(db, context.tenant_id, record)


@router.get("/attendances")
def attendances(
    patient_id: str | None = None,
    limit: int = Query(100, ge=1, le=100),
    offset: int = Query(0, ge=0),
    context: TenantContext = Depends(require("finance")),
    db: DbSession = Depends(get_db),
):
    query = select(Attendance).where(Attendance.organization_id == context.tenant_id)
    if patient_id:
        scoped(db, Patient, context.tenant_id, patient_id)
        query = query.where(Attendance.patient_id == patient_id)
    return [
        attendance_out(db, context.tenant_id, a)
        for a in db.scalars(
            query.order_by(Attendance.occurred_at.desc(), Attendance.id).limit(limit).offset(offset)
        )
    ]


@router.get("/payments")
def payments(
    attendance_id: str,
    context: TenantContext = Depends(require("finance")),
    db: DbSession = Depends(get_db),
):
    scoped(db, Attendance, context.tenant_id, attendance_id)
    return [
        payment_out(p)
        for p in db.scalars(
            select(Payment)
            .where(
                Payment.organization_id == context.tenant_id, Payment.attendance_id == attendance_id
            )
            .order_by(Payment.received_at, Payment.id)
        )
    ]


@router.post("/payments", status_code=201)
def pay(
    body: PaymentInput,
    idempotency_key: str = Header(
        alias="Idempotency-Key", min_length=16, max_length=80, pattern=r"^[A-Za-z0-9-]+$"
    ),
    context: TenantContext = Depends(require("finance", "finance.write")),
    db: DbSession = Depends(get_db),
):
    attendance = scoped(db, Attendance, context.tenant_id, body.attendance_id, lock=True)
    professional_permission(
        context, scoped(db, Professional, context.tenant_id, attendance.professional_id)
    )

    def existing_payment():
        item = db.scalar(
            select(Payment).where(
                Payment.organization_id == context.tenant_id,
                Payment.idempotency_key == idempotency_key,
            )
        )
        if item and (
            item.attendance_id != body.attendance_id
            or item.amount_cents != body.amount_cents
            or item.method != body.method
        ):
            raise HTTPException(409, "Chave de operação já usada com outros dados")
        return item

    existing = existing_payment()
    if existing:
        return payment_out(existing)
    if body.amount_cents > attendance.price_cents - paid_for(db, context.tenant_id, attendance.id):
        raise HTTPException(409, "Valor excede o saldo do atendimento")
    payment = Payment(
        organization_id=context.tenant_id,
        **body.model_dump(),
        received_at=now(),
        idempotency_key=idempotency_key,
    )
    db.add(payment)
    try:
        db.flush()
        audit(db, context.user.id, context.tenant_id, "payment.created", payment.id)
        db.commit()
    except IntegrityError:
        db.rollback()
        existing = existing_payment()
        if existing:
            return payment_out(existing)
        raise HTTPException(
            409, "Operação concorrente; consulte o saldo antes de repetir"
        ) from None
    return payment_out(payment)


@router.get("/dashboard")
def dashboard(
    context: TenantContext = Depends(require("dashboard")), db: DbSession = Depends(get_db)
):
    result = balance_for(db, context.tenant_id)
    result["patients"] = db.scalar(
        select(func.count())
        .select_from(Patient)
        .where(Patient.organization_id == context.tenant_id, Patient.active.is_(True))
    )
    result["scheduled"] = db.scalar(
        select(func.count())
        .select_from(Appointment)
        .where(
            Appointment.organization_id == context.tenant_id,
            Appointment.status == "SCHEDULED",
            Appointment.starts_at >= now(),
        )
    )
    return result


@router.get("/reports/summary")
def report(
    start: int,
    end: int,
    format: Literal["json", "csv"] = "json",
    context: TenantContext = Depends(require("reports")),
    db: DbSession = Depends(get_db),
):
    if end <= start or end - start > 366 * 86400:
        raise HTTPException(422, "Selecione período de até 366 dias")
    charged, count = db.execute(
        select(func.coalesce(func.sum(Attendance.price_cents), 0), func.count()).where(
            Attendance.organization_id == context.tenant_id,
            Attendance.occurred_at >= start,
            Attendance.occurred_at < end,
        )
    ).one()
    received = db.scalar(
        select(func.coalesce(func.sum(Payment.amount_cents), 0)).where(
            Payment.organization_id == context.tenant_id,
            Payment.received_at >= start,
            Payment.received_at < end,
        )
    )
    result = {
        "start": start,
        "end": end,
        "attendances": count,
        "charged_cents": charged,
        "received_cents": received,
        "outstanding_total_cents": balance_for(db, context.tenant_id)["balance_cents"],
    }
    if format == "csv":
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(result.keys())
        writer.writerow(result.values())
        return Response(
            output.getvalue(),
            media_type="text/csv",
            headers={"Content-Disposition": 'attachment; filename="resumo.csv"'},
        )
    return result


@router.get("/patients/{patient_id}/whatsapp")
def whatsapp(
    patient_id: str,
    kind: Literal["balance", "reminder"] = "balance",
    context: TenantContext = Depends(require("whatsapp")),
    db: DbSession = Depends(get_db),
):
    patient = scoped(db, Patient, context.tenant_id, patient_id)
    if not patient.phone:
        raise HTTPException(400, "Cadastre telefone com código do país e DDD")
    balance = balance_for(db, context.tenant_id, patient.id)["balance_cents"]
    if kind == "balance":
        amount = f"{balance // 100},{balance % 100:02d}"
        message = f"Olá! Há um saldo de R$ {amount} em aberto. Podemos combinar o pagamento?"
    else:
        message = (
            "Olá! Passando para lembrar do seu agendamento. Se precisar ajustar, entre em contato."
        )
    return {
        "phone": patient.phone,
        "message": message,
        "balance_cents": balance,
        "url": "https://wa.me/" + patient.phone + "?text=" + quote(message),
    }
