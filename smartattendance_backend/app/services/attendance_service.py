# app/services/attendance_service.py
"""
=============================================================================
SERVICIO: AttendanceService
=============================================================================
QUÉ HACE:
Gestiona la lógica de negocio para el registro, consulta y sincronización offline
de asistencias laborales de los empleados.

PARA QUÉ SIRVE:
Garantiza el ciclo de vida de asistencia (entradas, almuerzos, salidas y horas extras),
previniendo duplicados con idempotencia de marcas y sincronizando con Google Sheets.

PRINCIPIOS SOLID APLICADOS:
- S (Single Responsibility): Enfocado exclusivamente en el ciclo de vida de asistencia.
- D (Dependency Inversion): Inyecta repositorios de base de datos.
=============================================================================
"""
from datetime import date, datetime, time
from zoneinfo import ZoneInfo
from sqlalchemy.orm import Session
from fastapi import HTTPException, status, BackgroundTasks

from app.core.config import settings
from app.repositories.attendance_repository import AttendanceRepository
from app.repositories.user_repository import UserRepository
from app.schemas.attendance import AttendanceCreate, AttendanceResponse
from app.schemas.sync import AttendanceOfflineItem, AttendanceBatchSyncResponse
from app.services.sheets_service import SheetsService
from app.services.attendance_export_service import AttendanceExportService


class AttendanceService:
    """Orquesta el registro y consulta de asistencia laboral."""

    def __init__(self, db: Session) -> None:
        self.db = db
        self._repo = AttendanceRepository(db)
        self._user_repo = UserRepository(db)
        self._export_service = AttendanceExportService(db)

    def register(self, data: AttendanceCreate, background_tasks: BackgroundTasks) -> AttendanceResponse:
        """Registra una marca laboral garantizando validación y enriquecimiento server-side."""
        user = self._user_repo.get_by_id(data.usuario_id)
        if user is None or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Usuario con id={data.usuario_id} no encontrado o inactivo.",
            )

        if data.uuid_marca:
            existing = self._repo.get_by_uuid_marca(data.uuid_marca)
            if existing:
                return AttendanceResponse.model_validate(existing)

        tipo = data.tipo or self._decide_tipo(data.usuario_id)
        create_data = data.model_copy(update={"tipo": tipo})
        record = self._repo.create(create_data)

        # Sincronización en segundo plano con Google Sheets
        sheets_service = SheetsService(self.db)
        background_tasks.add_task(sheets_service.sync_to_google_sheets, record.id)

        return AttendanceResponse.model_validate(record)

    def sync_offline_batch(
        self,
        records: list[AttendanceOfflineItem],
        background_tasks: BackgroundTasks,
    ) -> AttendanceBatchSyncResponse:
        """Procesa un lote de marcas capturadas offline de forma idempotente y segura."""
        procesados = 0
        ignorados_duplicados = 0
        errores = 0
        detalles = []

        sheets_service = SheetsService(self.db)
        existing_by_uuid = self._repo.get_by_uuid_marcas([item.uuid_marca for item in records])
        users_by_id = self._user_repo.get_by_ids([item.usuario_id for item in records])

        for item in records:
            try:
                if item.uuid_marca in existing_by_uuid:
                    ignorados_duplicados += 1
                    detalles.append({"uuid_marca": item.uuid_marca, "status": "duplicado_ignorado"})
                    continue

                user = users_by_id.get(item.usuario_id)
                if user is None or not user.is_active:
                    errores += 1
                    detalles.append({"uuid_marca": item.uuid_marca, "status": "error_usuario_inactivo_o_no_encontrado"})
                    continue

                tipo = item.tipo or self._decide_tipo(item.usuario_id)
                record = self._repo.create_from_offline(
                    usuario_id=item.usuario_id, tipo=tipo,
                    fecha_hora_local=item.fecha_hora_local, uuid_marca=item.uuid_marca,
                    latitud=item.latitud, longitud=item.longitud, direccion=item.direccion,
                )
                existing_by_uuid[item.uuid_marca] = record
                background_tasks.add_task(sheets_service.sync_to_google_sheets, record.id)
                procesados += 1
                detalles.append({"uuid_marca": item.uuid_marca, "status": "creado", "id": record.id})
            except Exception as e:
                errores += 1
                detalles.append({"uuid_marca": item.uuid_marca, "status": "error", "mensaje": str(e)})

        return AttendanceBatchSyncResponse(
            procesados=procesados, ignorados_duplicados=ignorados_duplicados,
            errores=errores, detalles=detalles,
        )

    def _decide_tipo(self, user_id: int) -> str:
        """Determina de forma determinista el tipo de jornada en el servidor."""
        last_today = self._repo.get_last_today(user_id)
        if last_today is None:
            return "entrada"
        return {
            "entrada": "salida_almuerzo",
            "salida_almuerzo": "regreso_almuerzo",
            "regreso_almuerzo": "salida",
            "salida": "entrada",
        }.get(last_today.tipo, "entrada")

    def get_all(self, skip: int = 0, limit: int = 100) -> list[AttendanceResponse]:
        return [AttendanceResponse.model_validate(r) for r in self._repo.list_all(skip=skip, limit=limit)]

    def get_all_with_users(self, skip: int = 0, limit: int = 100) -> list[dict]:
        records = self._repo.list_all_with_users(skip=skip, limit=limit)
        return [
            {
                **AttendanceResponse.model_validate(r).model_dump(),
                "nombre": r.user.nombre if r.user else "Desconocido",
                "apellido": r.user.apellido if r.user else "",
                "cedula": r.user.cedula if r.user else "",
                "cargo": r.user.cargo if r.user else None,
            }
            for r in records
        ]

    def get_by_user(self, user_id: int, skip: int = 0, limit: int = 100) -> list[AttendanceResponse]:
        if not self._user_repo.get_by_id(user_id):
            raise HTTPException(status_code=404, detail=f"Usuario con id={user_id} no encontrado.")
        return [AttendanceResponse.model_validate(r) for r in self._repo.list_by_user(user_id, skip=skip, limit=limit)]

    def get_by_date(self, target_date: date, skip: int = 0, limit: int = 200) -> list[AttendanceResponse]:
        return [AttendanceResponse.model_validate(r) for r in self._repo.list_by_date(target_date, skip=skip, limit=limit)]

    def export_excel(self, fecha_desde: date | None = None, fecha_hasta: date | None = None) -> bytes:
        return self._export_service.export_excel(fecha_desde, fecha_hasta)

    def export_csv(self, fecha_desde: date | None = None, fecha_hasta: date | None = None) -> bytes:
        return self._export_service.export_csv(fecha_desde, fecha_hasta)

    def export_preview(self, fecha_desde: date | None = None, fecha_hasta: date | None = None) -> dict:
        return self._export_service.export_preview(fecha_desde, fecha_hasta)

    def today_status(self) -> list[dict]:
        """Calcula el estado diario de puntualidad de todo el personal activo."""
        tz = ZoneInfo(settings.TIMEZONE)
        now = datetime.now(tz)
        today = now.date()
        h, m = map(int, settings.HORA_ENTRADA_LIMITE.split(":"))
        deadline = time(h, m)

        active_users = [u for u in self._user_repo.list_all(limit=1000) if u.is_active]
        if not active_users:
            return []

        entradas = self._repo.get_first_entrance_today_batch([u.id for u in active_users])
        result = []
        for u in active_users:
            entrada = entradas.get(u.id)
            estado = "sin_marcar"
            minutos_tarde = 0
            if entrada is not None:
                estado = "a_tiempo"
                if entrada > deadline:
                    estado = "tarde"
                    minutos_tarde = max(0, int((datetime.combine(today, entrada) - datetime.combine(today, deadline)).total_seconds() // 60))

            result.append({
                "id": u.id,
                "nombre": u.nombre,
                "apellido": u.apellido,
                "cedula": u.cedula,
                "cargo": u.cargo,
                "foto_url": u.foto_url,
                "estado": estado,
                "hora_entrada": entrada.strftime("%H:%M:%S") if entrada else None,
                "minutos_tarde": minutos_tarde,
            })

        prioridad = {"tarde": 0, "sin_marcar": 1, "a_tiempo": 2}
        result.sort(key=lambda x: (prioridad.get(x["estado"], 3), x["cargo"] or ""))
        return result
