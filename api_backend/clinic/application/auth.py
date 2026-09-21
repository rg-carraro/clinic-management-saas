import secrets
from dataclasses import dataclass

from fastapi import Depends, Header, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import delete, select, update
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert
from sqlalchemy.orm import Session as DbSession

from clinic.domain.access import PERMISSIONS, entitlements
from clinic.domain.models import AuditEvent, Membership, RateBucket, Session, Subscription, User
from clinic.infrastructure.database import get_db
from clinic.infrastructure.security import now, token_hash
from clinic.shared.config import get_settings

bearer = HTTPBearer(auto_error=False)


def audit(db, actor, tenant, action, target=None):
    db.add(
        AuditEvent(
            actor_id=actor,
            organization_id=tenant,
            action=action,
            target_id=target,
            occurred_at=now(),
        )
    )


def throttle(db, key: str, limit: int = 10, seconds: int = 900):
    timestamp = now()
    db.execute(delete(RateBucket).where(RateBucket.expires_at <= timestamp))
    digest = token_hash(key + ":" + str(timestamp // seconds))
    insert = sqlite_insert if db.bind.dialect.name == "sqlite" else pg_insert
    db.execute(
        insert(RateBucket)
        .values(key=digest, hits=0, expires_at=timestamp + seconds)
        .on_conflict_do_nothing(index_elements=["key"])
    )
    hits = db.execute(
        update(RateBucket)
        .where(RateBucket.key == digest)
        .values(hits=RateBucket.hits + 1)
        .returning(RateBucket.hits)
    ).scalar_one()
    db.commit()
    if hits > limit:
        raise HTTPException(
            429,
            "Muitas tentativas. Tente novamente mais tarde.",
            headers={"Retry-After": str(seconds)},
        )


def new_session(db, user_id: str) -> str:
    token = secrets.token_urlsafe(48)
    db.add(
        Session(
            token_hash=token_hash(token),
            user_id=user_id,
            expires_at=now() + get_settings().session_hours * 3600,
        )
    )
    return token


def identity(
    db: DbSession = Depends(get_db),
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
) -> User:
    if not credentials:
        raise HTTPException(401, "Autenticação necessária")
    session = db.get(Session, token_hash(credentials.credentials))
    if not session or session.expires_at <= now():
        raise HTTPException(401, "Sessão inválida ou expirada")
    user = db.get(User, session.user_id)
    if not user:
        raise HTTPException(401, "Sessão inválida")
    return user


@dataclass
class TenantContext:
    user: User
    tenant_id: str
    role: str
    features: list[str]


def tenant_context(
    user: User = Depends(identity),
    tenant_id: str = Header(alias="X-Tenant-ID"),
    db: DbSession = Depends(get_db),
) -> TenantContext:
    membership = db.scalar(
        select(Membership).where(
            Membership.organization_id == tenant_id,
            Membership.user_id == user.id,
            Membership.active.is_(True),
        )
    )
    if not membership:
        raise HTTPException(403, "Organização não autorizada")
    subscription = db.get(Subscription, tenant_id)
    features = (
        entitlements(subscription, now(), get_settings().disabled_features) if subscription else []
    )
    if membership.role != "OWNER" and "team" not in features:
        raise HTTPException(403, "Acesso de equipe requer plano Pro ativo")
    return TenantContext(user, tenant_id, membership.role, features)


def require(feature: str, permission: str = "read"):
    def authorize(context: TenantContext = Depends(tenant_context)):
        if permission not in PERMISSIONS.get(context.role, set()):
            raise HTTPException(403, "Permissão insuficiente")
        if feature not in context.features:
            raise HTTPException(403, "Recurso indisponível no plano atual")
        return context

    return authorize
