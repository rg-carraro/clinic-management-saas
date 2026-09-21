"""Restricted operator CLI; requires direct database credentials, never exposed as HTTP."""

import argparse

from clinic.application.auth import audit
from clinic.domain.models import Subscription
from clinic.infrastructure.database import SessionLocal
from clinic.infrastructure.security import now


def main():
    parser = argparse.ArgumentParser(description="Conceder licença comercial pelo operador")
    parser.add_argument("organization_id")
    parser.add_argument("--license", choices=["FOUNDER", "PAID"], required=True)
    parser.add_argument("--tier", choices=["ESSENTIAL", "PRO"], required=True)
    parser.add_argument("--paid-days", type=int)
    args = parser.parse_args()
    if args.license == "PAID" and (not args.paid_days or not 1 <= args.paid_days <= 3660):
        parser.error("PAID requer --paid-days entre 1 e 3660")
    with SessionLocal() as db:
        subscription = db.get(Subscription, args.organization_id)
        if not subscription:
            parser.error("Organização não encontrada")
        subscription.license = args.license
        subscription.tier = args.tier
        subscription.paid_until = now() + args.paid_days * 86400 if args.license == "PAID" else None
        audit(db, None, args.organization_id, "subscription.operator_grant")
        db.commit()
    print("Licença atualizada e auditada.")


if __name__ == "__main__":
    main()
