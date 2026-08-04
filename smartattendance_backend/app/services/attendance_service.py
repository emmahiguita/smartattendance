# app/services/attendance_service.py
"""
Attendance service â€” business logic for registering and querying attendance.
SRP: handles only attendance use cases.
"""
from datetime import date, datetime, time
from zoneinfo import ZoneInfo

from sqlalchemy.orm import Session

from app.core.config import settings
from app.repositories.attendance_repository import AttendanceRepository
from app.repositories.user_repository import UserRepository
from app.schemas.attendance import AttendanceCreate, AttendanceResponse
from app.schemas.sync import AttendanceOfflineItem, AttendanceBatchSyncResponse
from fastapi import HTTPException, status, BackgroundTasks
from app.services.sheets_service import SheetsService


class AttendanceService:
    """Orchestrates attendance registration and history queries."""

    def __init__(self, db: Session) -> None:
        self.db = db
        self._repo = AttendanceRepository(db)
        self._user_repo = UserRepository(db)

    def register(self, data: AttendanceCreate, background_tasks: BackgroundTasks) -> AttendanceResponse:
        """Record an attendance entry or exit for a valid, active user.

        The `tipo` field is decided SERVER-SIDE: when omitted, it is derived from
        the user's workday state (entrada if the day is open, salida if an entry
        exists without a matching exit). The client clock is never trusted.
        """
        user = self._user_repo.get_by_id(data.usuario_id)
        if user is None or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Usuario con id={data.usuario_id} no encontrado o inactivo.",
            )

        # Si viene con uuid_marca, verificar si ya existe (idempotencia)
        if data.uuid_marca:
            existing = self._repo.get_by_uuid_marca(data.uuid_marca)
            if existing:
                return AttendanceResponse.model_validate(existing)

        tipo = data.tipo or self._decide_tipo(data.usuario_id)
        create_data = data.model_copy(update={"tipo": tipo})
        record = self._repo.create(create_data)

        # Sincronizar con Google Sheets en segundo plano (pasa ID, no objeto)
        sheets_service = SheetsService(self.db)
        background_tasks.add_task(sheets_service.sync_to_google_sheets, record.id)

        return AttendanceResponse.model_validate(record)

    def sync_offline_batch(
        self,
        records: list[AttendanceOfflineItem],
        background_tasks: BackgroundTasks,
    ) -> AttendanceBatchSyncResponse:
        """Procesa un lote de marcas registradas en modo offline con idempotencia."""
        procesados = 0
        ignorados_duplicados = 0
        errores = 0
        detalles = []

        sheets_service = SheetsService(self.db)
        existing_by_uuid = self._repo.get_by_uuid_marcas(
            [item.uuid_marca for item in records]
        )
        users_by_id = self._user_repo.get_by_ids(
            [item.usuario_id for item in records]
        )

        for item in records:
            try:
                # 1. Comprobar si ya se procesó esta uuid_marca
                existing = existing_by_uuid.get(item.uuid_marca)
                if existing is not None:
                    ignorados_duplicados += 1
                    detalles.append({
                        "uuid_marca": item.uuid_marca,
                        "status": "duplicado_ignorado",
                        "id": existing.id,
                    })
                    continue

                # 2. Verificar usuario activo
                user = users_by_id.get(item.usuario_id)
                if user is None or not user.is_active:
                    errores += 1
                    detalles.append({
                        "uuid_marca": item.uuid_marca,
                        "status": "error_usuario_inactivo_o_no_encontrado",
                    })
                    continue

                # 3. Determinar tipo si es nulo
                tipo = item.tipo or self._decide_tipo(item.usuario_id)

                # 4. Crear registro con timestamp local capturado
                record = self._repo.create_from_offline(
                    usuario_id=item.usuario_id,
                    tipo=tipo,
                    fecha_hora_local=item.fecha_hora_local,
                    uuid_marca=item.uuid_marca,
                    latitud=item.latitud,
                    longitud=item.longitud,
                    direccion=item.direccion,
                )

                existing_by_uuid[item.uuid_marca] = record
                background_tasks.add_task(sheets_service.sync_to_google_sheets, record.id)
                procesados += 1
                detalles.append({
                    "uuid_marca": item.uuid_marca,
                    "status": "creado",
                    "id": record.id,
                })

            except Exception as e:
                errores += 1
                detalles.append({
                    "uuid_marca": item.uuid_marca,
                    "status": "error",
                    "mensaje": str(e),
                })

        return AttendanceBatchSyncResponse(
            procesados=procesados,
            ignorados_duplicados=ignorados_duplicados,
            errores=errores,
            detalles=detalles,
        )


    def _decide_tipo(self, user_id: int) -> str:
        """Máquina de estado de la jornada (4 marcas), SERVER-SIDE.

        - Sin registro hoy, o el día termina con 'salida'     â†’ 'entrada'
        - Ãšltimo registro hoy es 'entrada'                    â†’ 'salida_almuerzo'
        - Ãšltimo registro hoy es 'salida_almuerzo'            â†’ 'regreso_almuerzo'
        - Ãšltimo registro hoy es 'regreso_almuerzo'           â†’ 'salida'
        - Ãšltimo registro hoy es 'salida'                     â†’ 'entrada' (nueva jornada)
        """
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
        records = self._repo.list_all(skip=skip, limit=limit)
        return [AttendanceResponse.model_validate(r) for r in records]

    def get_all_with_users(self, skip: int = 0, limit: int = 100) -> list[dict]:
        """Return attendance records enriched with user names + área (cargo)."""
        records = self._repo.list_all_with_users(skip=skip, limit=limit)
        result = []
        for r in records:
            data = AttendanceResponse.model_validate(r).model_dump()
            if r.user:
                data["nombre"] = r.user.nombre
                data["apellido"] = r.user.apellido
                data["cedula"] = r.user.cedula
                data["cargo"] = r.user.cargo  # área organizacional para agrupar
            else:
                data["nombre"] = "Desconocido"
                data["apellido"] = ""
                data["cedula"] = ""
                data["cargo"] = None
            result.append(data)
        return result

    def get_by_user(self, user_id: int, skip: int = 0, limit: int = 100) -> list[AttendanceResponse]:
        self._assert_user_exists(user_id)
        records = self._repo.list_by_user(user_id, skip=skip, limit=limit)
        return [AttendanceResponse.model_validate(r) for r in records]

    def get_by_date(self, target_date: date, skip: int = 0, limit: int = 200) -> list[AttendanceResponse]:
        records = self._repo.list_by_date(target_date, skip=skip, limit=limit)
        return [AttendanceResponse.model_validate(r) for r in records]

    def export_excel(
        self,
        fecha_desde: date | None = None,
        fecha_hasta: date | None = None,
    ) -> bytes:
        """Genera un archivo Excel con las asistencias, opcionalmente filtrado por rango de fechas."""
        records = self._repo.list_all(
            skip=0, limit=10000, fecha_desde=fecha_desde, fecha_hasta=fecha_hasta
        )
        sheets_service = SheetsService(self.db)
        return sheets_service.generate_excel_bytes(records)

    def today_status(self) -> list[dict]:
        """Estado de asistencia HOY para TODOS los empleados activos.

        Retorna nombre, cargo, foto, hora de entrada, y si llegó a tiempo,
        tarde o no ha marcado. La hora límite de entrada se configura en
        settings.HORA_ENTRADA_LIMITE (por defecto 08:30 Colombia).

        Optimizado: una sola query batch para todas las entradas del día
        en lugar de N+1 consultas individuales por usuario.
        """
        tz = ZoneInfo(settings.TIMEZONE)
        now = datetime.now(tz)
        today = now.date()
        h, m = map(int, settings.HORA_ENTRADA_LIMITE.split(":"))
        deadline = time(h, m)

        users = self._user_repo.list_all(limit=1000)
        active_users = [u for u in users if u.is_active]
        if not active_users:
            return []

        # Batch: una sola query para todas las primeras entradas de hoy
        user_ids = [u.id for u in active_users]
        entradas = self._repo.get_first_entrance_today_batch(user_ids)

        result = []
        for u in active_users:
            entrada = entradas.get(u.id)
            estado = "sin_marcar"
            minutos_tarde = 0

            if entrada is not None:
                estado = "a_tiempo"
                if entrada > deadline:
                    estado = "tarde"
                    t_ent = datetime.combine(today, entrada)
                    t_dead = datetime.combine(today, deadline)
                    minutos_tarde = max(0, int((t_ent - t_dead).total_seconds() // 60))

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

        # Ordenar: tarde primero (más urgente), luego sin_marcar, luego a_tiempo.
        prioridad = {"tarde": 0, "sin_marcar": 1, "a_tiempo": 2}
        result.sort(key=lambda x: (prioridad.get(x["estado"], 3), x["cargo"] or ""))
        return result

    # â”€â”€ Private helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    def _assert_user_exists(self, user_id: int) -> None:
        if not self._user_repo.get_by_id(user_id):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Usuario con id={user_id} no encontrado.",
            )




