# app/repositories/attendance_repository.py
"""
Attendance repository â€” abstracts all DB queries for attendance.
SRP: only attendance-related DB access.
"""
from datetime import date, datetime, time
from zoneinfo import ZoneInfo

from sqlalchemy.orm import Session, joinedload

from app.core.config import settings
from app.models.attendance import Attendance
from app.schemas.attendance import AttendanceCreate


class AttendanceRepository:
    """Single responsibility: CRUD operations on the Attendance table."""

    def __init__(self, db: Session) -> None:
        self._db = db

    @staticmethod
    def _now_business() -> datetime:
        """Fecha/hora de NEGOCIO: la zona de la empresa (settings.TIMEZONE),
        NO la zona del servidor. Colombia = America/Bogota (UTC-5)."""
        return datetime.now(ZoneInfo(settings.TIMEZONE))

    def get_by_id(self, record_id: int) -> Attendance | None:
        return self._db.get(Attendance, record_id)

    def get_by_uuid_marca(self, uuid_marca: str) -> Attendance | None:
        return (
            self._db.query(Attendance)
            .filter(Attendance.uuid_marca == uuid_marca)
            .first()
        )

    def get_by_uuid_marcas(self, uuid_marcas: list[str]) -> dict[str, Attendance]:
        """Carga marcas existentes en una consulta para sincronización por lotes."""
        if not uuid_marcas:
            return {}
        records = (
            self._db.query(Attendance)
            .filter(Attendance.uuid_marca.in_(set(uuid_marcas)))
            .all()
        )
        return {record.uuid_marca: record for record in records if record.uuid_marca}

    def list_all(
        self,
        skip: int = 0,
        limit: int = 100,
        fecha_desde: date | None = None,
        fecha_hasta: date | None = None,
    ) -> list[Attendance]:
        query = self._db.query(Attendance)
        if fecha_desde is not None:
            query = query.filter(Attendance.fecha >= fecha_desde)
        if fecha_hasta is not None:
            query = query.filter(Attendance.fecha <= fecha_hasta)
        return (
            query.order_by(Attendance.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    def list_all_with_users(self, skip: int = 0, limit: int = 100) -> list[Attendance]:
        """Eagerly load user relationship to avoid N+1 queries."""
        return (
            self._db.query(Attendance)
            .options(joinedload(Attendance.user))
            .order_by(Attendance.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    def list_by_user(self, user_id: int, skip: int = 0, limit: int = 100) -> list[Attendance]:
        return (
            self._db.query(Attendance)
            .filter(Attendance.usuario_id == user_id)
            .order_by(Attendance.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    def list_by_date(self, target_date: date, skip: int = 0, limit: int = 200) -> list[Attendance]:
        return (
            self._db.query(Attendance)
            .filter(Attendance.fecha == target_date)
            .order_by(Attendance.hora.asc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    def get_last_today(self, user_id: int) -> Attendance | None:
        """Return the most recent attendance record for today, ordered by hora desc.
        Queries by date filter directly â€” avoids the limit-100 bug in _decide_tipo.
        "Hoy" = día de NEGOCIO (settings.TIMEZONE), no la fecha del servidor."""
        today = self._now_business().date()
        return (
            self._db.query(Attendance)
            .filter(Attendance.usuario_id == user_id, Attendance.fecha == today)
            .order_by(Attendance.hora.desc())
            .first()
        )

    def get_first_entrance_today_batch(self, user_ids: list[int]) -> dict[int, time | None]:
        """Retorna la primera entrada de HOY para un lote de usuarios en UNA sola query.
        Evita el N+1 en today_status: en lugar de consultar por cada usuario,
        se hace un subquery con MIN(hora) agrupado por usuario_id filtrando tipo='entrada'
        y fecha=hoy (zona de negocio). Retorna dict[user_id, hora | None]."""
        if not user_ids:
            return {}
        today = self._now_business().date()
        from sqlalchemy import func
        rows = (
            self._db.query(
                Attendance.usuario_id,
                func.min(Attendance.hora).label("primera_entrada"),
            )
            .filter(
                Attendance.usuario_id.in_(user_ids),
                Attendance.fecha == today,
                Attendance.tipo == "entrada",
            )
            .group_by(Attendance.usuario_id)
            .all()
        )
        return {row.usuario_id: row.primera_entrada for row in rows}

    def create(self, data: AttendanceCreate) -> Attendance:
        # Fecha/hora de NEGOCIO (settings.TIMEZONE, Colombia): la marca
        # pertenece al día del país de la empresa, aunque el servidor corra
        # en otra zona horaria.
        now = self._now_business()
        record = Attendance(
            usuario_id=data.usuario_id,
            tipo=data.tipo,
            fecha=now.date(),
            hora=now.time(),
            latitud=data.latitud,
            longitud=data.longitud,
            direccion=data.direccion,
            uuid_marca=data.uuid_marca,
        )
        self._db.add(record)
        self._db.commit()
        self._db.refresh(record)
        return record

    def create_from_offline(
        self,
        usuario_id: int,
        tipo: str,
        fecha_hora_local: datetime,
        uuid_marca: str,
        latitud: float | None = None,
        longitud: float | None = None,
        direccion: str | None = None,
    ) -> Attendance:
        record = Attendance(
            usuario_id=usuario_id,
            tipo=tipo,
            fecha=fecha_hora_local.date(),
            hora=fecha_hora_local.time(),
            latitud=latitud,
            longitud=longitud,
            direccion=direccion,
            uuid_marca=uuid_marca,
        )
        self._db.add(record)
        self._db.commit()
        self._db.refresh(record)
        return record


