from alembic import context

from clinic.domain import models, operations  # noqa: F401
from clinic.infrastructure.database import Base, make_engine
from clinic.shared.config import get_settings


def migrate(connection):
    context.configure(connection=connection, target_metadata=Base.metadata, compare_type=True)
    with context.begin_transaction():
        context.run_migrations()


if context.is_offline_mode():
    context.configure(
        url=get_settings().database_url, target_metadata=Base.metadata, literal_binds=True
    )
    with context.begin_transaction():
        context.run_migrations()
elif context.config.attributes.get("connection") is not None:
    migrate(context.config.attributes["connection"])
else:
    with make_engine(get_settings().database_url).connect() as connection:
        migrate(connection)
