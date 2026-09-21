from clinic.domain.models import Subscription

ESSENTIAL = {"patients", "agenda", "attendances", "finance", "whatsapp", "dashboard", "reports"}
PRO = ESSENTIAL | {"team"}
PERMISSIONS = {
    "OWNER": {
        "read",
        "patients.write",
        "agenda.write",
        "attendance.write",
        "finance.write",
        "catalog.write",
        "team.write",
    },
    "ADMIN": {
        "read",
        "patients.write",
        "agenda.write",
        "attendance.write",
        "finance.write",
        "catalog.write",
        "team.write",
    },
    "PROFESSIONAL": {"read", "patients.write", "agenda.write", "attendance.write", "finance.write"},
    "STAFF": {"read", "patients.write", "agenda.write", "finance.write"},
}


def entitlements(subscription: Subscription, now: int, disabled: list[str]) -> list[str]:
    active = (
        subscription.license == "FOUNDER"
        or (subscription.license == "TRIAL" and now < subscription.trial_ends_at)
        or (
            subscription.license == "PAID"
            and subscription.paid_until is not None
            and now < subscription.paid_until
        )
    )
    if not active:
        return []
    return sorted((PRO if subscription.tier == "PRO" else ESSENTIAL) - set(disabled))
