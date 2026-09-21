from alembic import context

from clinic.domain import models  # noqa: F401
from clinic.infrastructure.database import Base, make_engine
from clinic.shared.config import get_settings

target_metadata = Base.metadata
if context.is_offline_mode():
    context.configure(
        url=get_settings().database_url, target_metadata=target_metadata, literal_binds=True
    )
    with context.begin_transaction():
        context.run_migrations()
else:
    with make_engine(get_settings().database_url).connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata, compare_type=True)
        with context.begin_transaction():
            context.run_migrations()
