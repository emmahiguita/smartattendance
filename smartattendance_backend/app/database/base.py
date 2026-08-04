# app/database/base.py
"""
Database engine, session factory, and declarative base.
SRP: this module owns ONLY the database connection setup.
"""
from sqlalchemy import create_engine, event
from sqlalchemy.engine import make_url
from sqlalchemy.orm import sessionmaker, DeclarativeBase

from app.core.config import settings


class Base(DeclarativeBase):
    """Declarative base for all SQLAlchemy models."""
    pass


database_url = make_url(settings.DATABASE_URL)
is_sqlite = database_url.get_backend_name() == "sqlite"

engine_kwargs = {"echo": settings.DB_ECHO}

if is_sqlite:
    engine_kwargs["connect_args"] = {
        "check_same_thread": False,
        "timeout": settings.SQLITE_BUSY_TIMEOUT_MS / 1000,
    }
else:
    # Ajustes de pool para bases de datos de producciÃ³n (PostgreSQL, MySQL, SQL Server)
    engine_kwargs["pool_size"] = settings.DB_POOL_SIZE
    engine_kwargs["max_overflow"] = settings.DB_MAX_OVERFLOW
    engine_kwargs["pool_timeout"] = settings.DB_POOL_TIMEOUT_SECONDS
    engine_kwargs["pool_recycle"] = settings.DB_POOL_RECYCLE_SECONDS
    engine_kwargs["pool_pre_ping"] = True
    engine_kwargs["pool_use_lifo"] = True

    connect_args = {}
    if database_url.get_backend_name() == "postgresql":
        connect_args["connect_timeout"] = settings.DB_CONNECT_TIMEOUT_SECONDS
    elif database_url.get_backend_name() == "mysql":
        connect_args["connect_timeout"] = settings.DB_CONNECT_TIMEOUT_SECONDS
    if connect_args:
        engine_kwargs["connect_args"] = connect_args

engine = create_engine(
    settings.DATABASE_URL,
    **engine_kwargs,
)

if is_sqlite:
    @event.listens_for(engine, "connect")
    def set_sqlite_pragma(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA journal_mode=WAL")
        cursor.execute("PRAGMA synchronous=NORMAL")
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.execute(f"PRAGMA busy_timeout={settings.SQLITE_BUSY_TIMEOUT_MS}")
        cursor.close()


SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)



def get_db():
    """FastAPI dependency: yields a database session and ensures cleanup."""
    db = SessionLocal()
    try:
        yield db
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


def create_all_tables() -> None:
    """Create all tables. Called once on startup."""
    # Ensure every SQLAlchemy model is registered before creating schema.`n    import app.models  # noqa: F401`n    Base.metadata.create_all(bind=engine)
    # Migraciones ligeras (SQLite: CHECK constraints de SAEnum no se auto-migran)
    from app.database.migrate import run_migrations
    run_migrations(engine)





