import secrets
import smtplib
from typing import Literal

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request
from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator
from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session as DbSession

from clinic.application.auth import (
    TenantContext,
    audit,
    bearer,
    identity,
    new_session,
    require,
    tenant_context,
    throttle,
)
from clinic.domain.models import (
    Membership,
    Organization,
    PasswordReset,
    Session,
    Subscription,
    User,
)
from clinic.infrastructure.database import get_db
from clinic.infrastructure.mail import send_reset
from clinic.infrastructure.security import DUMMY_HASH, hasher, now, token_hash, verify_password

router = APIRouter(prefix="/v1", tags=["identity"])


class Input(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class Login(Input):
    email: EmailStr
    password: str = Field(min_length=12, max_length=128)

    @field_validator("email")
    @classmethod
    def lower_email(cls, value):
        return value.lower()


class Register(Login):
    name: str = Field(min_length=2, max_length=120)
    organization_name: str = Field(min_length=2, max_length=120)


class ResetRequest(Input):
    email: EmailStr


class ResetConfirm(Input):
    token: str = Field(min_length=30, max_length=200)
    password: str = Field(min_length=12, max_length=128)


class MemberInput(Input):
    email: EmailStr
    role: Literal["ADMIN", "PROFESSIONAL", "STAFF"]


def auth_limits(db, request, email):
    ip = request.client.host if request.client else "unknown"
    throttle(db, "auth-ip:" + ip, 60)
    throttle(db, "auth-email:" + email.lower(), 12)


def session_response(db, user, token):
    memberships = db.execute(
        select(Membership, Organization)
        .join(Organization, Membership.organization_id == Organization.id)
        .where(Membership.user_id == user.id, Membership.active.is_(True))
    ).all()
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {"id": user.id, "name": user.name, "email": user.email},
        "organizations": [
            {"id": org.id, "name": org.name, "role": member.role} for member, org in memberships
        ],
    }


@router.post("/auth/register", status_code=201)
def register(body: Register, request: Request, db: DbSession = Depends(get_db)):
    auth_limits(db, request, body.email)
    user = User(email=body.email, name=body.name, password_hash=hasher.hash(body.password))
    org = Organization(name=body.organization_name, created_at=now())
    try:
        db.add_all([user, org])
        db.flush()
        db.add(Membership(user_id=user.id, organization_id=org.id, role="OWNER"))
        db.add(
            Subscription(
                organization_id=org.id,
                tier="ESSENTIAL",
                license="TRIAL",
                trial_ends_at=now() + 7 * 86400,
            )
        )
        token = new_session(db, user.id)
        audit(db, user.id, org.id, "organization.created", org.id)
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            409, "Não foi possível cadastrar. Entre ou recupere sua senha."
        ) from None
    return session_response(db, user, token)


@router.post("/auth/login")
def login(body: Login, request: Request, db: DbSession = Depends(get_db)):
    auth_limits(db, request, body.email)
    user = db.scalar(select(User).where(User.email == body.email))
    valid = verify_password(user.password_hash if user else DUMMY_HASH, body.password)
    if not user or not valid:
        raise HTTPException(401, "E-mail ou senha inválidos")
    token = new_session(db, user.id)
    audit(db, user.id, None, "session.created")
    db.commit()
    return session_response(db, user, token)


@router.post("/auth/logout", status_code=204)
def logout(
    user: User = Depends(identity), credentials=Depends(bearer), db: DbSession = Depends(get_db)
):
    db.execute(delete(Session).where(Session.token_hash == token_hash(credentials.credentials)))
    audit(db, user.id, None, "session.revoked")
    db.commit()


def deliver_reset(email, token):
    try:
        send_reset(email, token)
    except (smtplib.SMTPException, OSError):
        # Deliberately omit recipient and token. Provider monitoring handles delivery failures.
        import logging

        logging.getLogger(__name__).error("Password reset delivery unavailable")


@router.post("/auth/password/forgot", status_code=202)
def forgot(
    body: ResetRequest, request: Request, tasks: BackgroundTasks, db: DbSession = Depends(get_db)
):
    auth_limits(db, request, body.email)
    user = db.scalar(select(User).where(User.email == body.email.lower()))
    if user:
        token = secrets.token_urlsafe(48)
        db.execute(delete(PasswordReset).where(PasswordReset.user_id == user.id))
        db.add(
            PasswordReset(token_hash=token_hash(token), user_id=user.id, expires_at=now() + 1800)
        )
        db.commit()
        tasks.add_task(deliver_reset, user.email, token)
    return {"message": "Se o e-mail estiver cadastrado, você receberá as instruções."}


@router.post("/auth/password/reset", status_code=204)
def reset(body: ResetConfirm, request: Request, db: DbSession = Depends(get_db)):
    throttle(db, "reset-ip:" + (request.client.host if request.client else "unknown"), 20)
    reset_token = db.execute(
        delete(PasswordReset)
        .where(PasswordReset.token_hash == token_hash(body.token), PasswordReset.expires_at > now())
        .returning(PasswordReset.user_id)
    ).scalar_one_or_none()
    if not reset_token:
        db.rollback()
        raise HTTPException(400, "Código inválido ou expirado")
    user = db.get(User, reset_token)
    user.password_hash = hasher.hash(body.password)
    db.execute(delete(Session).where(Session.user_id == user.id))
    db.execute(delete(PasswordReset).where(PasswordReset.user_id == user.id))
    audit(db, user.id, None, "password.reset")
    db.commit()


@router.get("/me")
def me(context: TenantContext = Depends(tenant_context), db: DbSession = Depends(get_db)):
    org = db.get(Organization, context.tenant_id)
    subscription = db.get(Subscription, context.tenant_id)
    return {
        "user": {"id": context.user.id, "name": context.user.name},
        "organization": {"id": org.id, "name": org.name},
        "role": context.role,
        "entitlements": context.features,
        "subscription": {
            "tier": subscription.tier,
            "license": subscription.license,
            "trial_ends_at": subscription.trial_ends_at,
        },
    }


@router.get("/members")
def members(
    context: TenantContext = Depends(require("team", "team.write")), db: DbSession = Depends(get_db)
):
    rows = db.execute(
        select(Membership, User)
        .join(User, Membership.user_id == User.id)
        .where(Membership.organization_id == context.tenant_id)
    ).all()
    return [
        {
            "id": member.id,
            "user_id": user.id,
            "name": user.name,
            "email": user.email,
            "role": member.role,
            "active": member.active,
        }
        for member, user in rows
    ]


@router.post("/members", status_code=201)
def add_member(
    body: MemberInput,
    context: TenantContext = Depends(require("team", "team.write")),
    db: DbSession = Depends(get_db),
):
    if body.role == "ADMIN" and context.role != "OWNER":
        raise HTTPException(403, "Somente OWNER pode conceder ADMIN")
    user = db.scalar(select(User).where(User.email == body.email.lower()))
    if not user:
        raise HTTPException(404, "Usuário deve criar uma conta antes de receber acesso")
    member = Membership(organization_id=context.tenant_id, user_id=user.id, role=body.role)
    db.add(member)
    try:
        db.flush()
        audit(db, context.user.id, context.tenant_id, "membership.created", member.id)
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Usuário já vinculado") from None
    return {"id": member.id, "role": member.role}


@router.post("/members/{member_id}/deactivate", status_code=204)
def deactivate(
    member_id: str,
    context: TenantContext = Depends(require("team", "team.write")),
    db: DbSession = Depends(get_db),
):
    member = db.scalar(
        select(Membership).where(
            Membership.id == member_id, Membership.organization_id == context.tenant_id
        )
    )
    if not member:
        raise HTTPException(404, "Vínculo não encontrado")
    if member.role == "OWNER" or (member.role == "ADMIN" and context.role != "OWNER"):
        raise HTTPException(403, "Não é permitido desativar este vínculo")
    member.active = False
    audit(db, context.user.id, context.tenant_id, "membership.deactivated", member.id)
    db.commit()
