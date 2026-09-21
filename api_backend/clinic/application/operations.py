from fastapi import HTTPException
from sqlalchemy import func, select, update

from clinic.domain.models import Organization
from clinic.domain.operations import Attendance, Payment


def scoped(db, model, tenant, record_id, lock=False):
    statement = select(model).where(model.organization_id == tenant, model.id == record_id)
    if lock:
        # SQLite ignores FOR UPDATE, so acquire its write lock before reading.
        if db.bind.dialect.name == "sqlite":
            db.execute(
                update(Organization).where(Organization.id == tenant).values(name=Organization.name)
            )
        statement = statement.with_for_update()
    record = db.scalar(statement)
    if not record:
        raise HTTPException(404, "Registro não encontrado")
    return record


def paid_for(db, tenant, attendance_id):
    return db.scalar(
        select(func.coalesce(func.sum(Payment.amount_cents), 0)).where(
            Payment.organization_id == tenant, Payment.attendance_id == attendance_id
        )
    )


def balance_for(db, tenant, patient_id=None):
    due_query = select(func.coalesce(func.sum(Attendance.price_cents), 0)).where(
        Attendance.organization_id == tenant
    )
    paid_query = (
        select(func.coalesce(func.sum(Payment.amount_cents), 0))
        .join(
            Attendance,
            (Payment.attendance_id == Attendance.id)
            & (Payment.organization_id == Attendance.organization_id),
        )
        .where(Attendance.organization_id == tenant)
    )
    if patient_id:
        due_query = due_query.where(Attendance.patient_id == patient_id)
        paid_query = paid_query.where(Attendance.patient_id == patient_id)
    due, paid = db.scalar(due_query), db.scalar(paid_query)
    return {"charged_cents": due, "paid_cents": paid, "balance_cents": due - paid}
