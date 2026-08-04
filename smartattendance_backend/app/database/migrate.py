# app/database/migrate.py
"""
Migraciones ligeras para SQLite (sin Alembic).

SQLite no soporta ALTER CONSTRAINT ni DROP COLUMN en versiones antiguas.
Estrategia: detectar columnas/constraints faltantes y aplicar ALTER TABLE ADD COLUMN
(para columnas nuevas nullable) o recrear la tabla cuando sea imprescindible.

Las migraciones se ejecutan después de create_all_tables() en cada arranque.
Son idempotentes: se puede correr varias veces sin daño.
"""
import logging
from sqlalchemy import inspect, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

CURRENT_ATTENDANCE_TYPES = ("entrada", "salida_almuerzo", "regreso_almuerzo", "salida")

# Columnas nullable agregadas al modelo User después de la creación inicial de la tabla.
USER_NULLABLE_COLUMNS = {
    "fecha_nacimiento":  "VARCHAR(20)",
    "telefono":          "VARCHAR(30)",
    "direccion":         "VARCHAR(255)",
    "hashed_password":   "VARCHAR(255)",
}

# Columnas nullable agregadas al modelo Attendance después de la creación inicial.
ATTENDANCE_NULLABLE_COLUMNS = {
    "latitud":   "FLOAT",
    "longitud":  "FLOAT",
    "direccion": "VARCHAR",
    "uuid_marca": "VARCHAR",
}



def run_migrations(engine: Engine) -> None:
    """Ejecuta todas las migraciones conocidas. Idempotente."""
    with Session(engine) as db:
        _migrate_users_columns(db, engine)
        _migrate_attendance_columns(db, engine)
        _migrate_attendance_type(db)


# ── Users ────────────────────────────────────────────────────────────────────

def _migrate_users_columns(db: Session, engine: Engine) -> None:
    """Agrega columnas nullable faltantes a la tabla users (ALTER TABLE ADD COLUMN)."""
    inspector = inspect(engine)
    if "users" not in inspector.get_table_names():
        return

    existing = {col["name"] for col in inspector.get_columns("users")}
    for col_name, col_type in USER_NULLABLE_COLUMNS.items():
        if col_name not in existing:
            db.execute(text(f"ALTER TABLE users ADD COLUMN {col_name} {col_type}"))
            db.commit()
            logger.info("[migrate] users: columna '%s' agregada.", col_name)


# ── Attendance columns ────────────────────────────────────────────────────────

def _migrate_attendance_columns(db: Session, engine: Engine) -> None:
    """Agrega columnas nullable faltantes a la tabla attendance."""
    inspector = inspect(engine)
    if "attendance" not in inspector.get_table_names():
        return

    existing = {col["name"] for col in inspector.get_columns("attendance")}
    for col_name, col_type in ATTENDANCE_NULLABLE_COLUMNS.items():
        if col_name not in existing:
            db.execute(text(f"ALTER TABLE attendance ADD COLUMN {col_name} {col_type}"))
            db.commit()
            logger.info("[migrate] attendance: columna '%s' agregada.", col_name)


# ── Attendance CHECK constraint (tipo enum) ──────────────────────────────────

def _migrate_attendance_type(db: Session) -> None:
    """Recrea `attendance` si su CHECK constraint no incluye los 4 tipos actuales."""
    # Recuperación de arranques anteriores que fallaron a mitad:
    # si quedó `attendance_old`, los datos originales están ahí.
    old_row = db.execute(
        text("SELECT sql FROM sqlite_master WHERE type='table' AND name='attendance_old'")
    ).scalar_one_or_none()
    if old_row is not None:
        db.execute(text("DROP TABLE IF EXISTS attendance"))
        db.execute(text("ALTER TABLE attendance_old RENAME TO attendance"))
        db.commit()
        logger.warning("[migrate] attendance_old encontrada; restaurada como attendance.")

    row = db.execute(
        text("SELECT sql FROM sqlite_master WHERE type='table' AND name='attendance'")
    ).scalar_one_or_none()

    if row is None:
        return

    sql = row.lower()
    missing = [t for t in CURRENT_ATTENDANCE_TYPES if t not in sql]
    if not missing:
        return

    logger.info("[migrate] attendance: tipos faltantes %s — recreando tabla.", missing)
    db.execute(text("PRAGMA foreign_keys=OFF"))
    db.execute(text("ALTER TABLE attendance RENAME TO attendance_old"))
    db.execute(text("DROP INDEX IF EXISTS ix_attendance_fecha"))
    db.execute(text("DROP INDEX IF EXISTS ix_attendance_usuario_id"))
    db.execute(text("DROP INDEX IF EXISTS ix_attendance_uuid_marca"))
    db.execute(text(
        """
        CREATE TABLE attendance (
            id          INTEGER NOT NULL PRIMARY KEY,
            usuario_id  INTEGER NOT NULL,
            fecha       DATE    NOT NULL,
            hora        TIME    NOT NULL,
            tipo        VARCHAR(20) NOT NULL,
            latitud     FLOAT,
            longitud    FLOAT,
            direccion   VARCHAR,
            uuid_marca  VARCHAR,
            created_at  DATETIME,
            CONSTRAINT fk_attendance_user FOREIGN KEY(usuario_id) REFERENCES users (id)
        )
        """
    ))
    db.execute(text("CREATE INDEX IF NOT EXISTS ix_attendance_fecha      ON attendance (fecha)"))
    db.execute(text("CREATE INDEX IF NOT EXISTS ix_attendance_usuario_id ON attendance (usuario_id)"))
    db.execute(text("CREATE INDEX IF NOT EXISTS ix_attendance_uuid_marca ON attendance (uuid_marca)"))

    db.execute(text(
        """
        INSERT INTO attendance
            (id, usuario_id, fecha, hora, tipo, latitud, longitud, direccion, uuid_marca, created_at)
        SELECT id, usuario_id, fecha, hora, tipo, latitud, longitud, direccion,
               CASE WHEN EXISTS (SELECT 1 FROM pragma_table_info('attendance_old') WHERE name='uuid_marca') THEN uuid_marca ELSE NULL END,
               created_at
        FROM attendance_old
        """
    ))
    db.execute(text("DROP TABLE attendance_old"))

    db.execute(text("PRAGMA foreign_keys=ON"))
    db.commit()
    logger.info("[migrate] attendance: tabla recreada con éxito.")
