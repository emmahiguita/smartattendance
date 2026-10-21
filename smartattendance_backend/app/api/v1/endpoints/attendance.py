# app/api/v1/endpoints/attendance.py
"""
Attendance endpoints — CRUD for attendance records.
SRP: router delegates all logic to AttendanceService.
"""
from datetime import date
from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from fastapi.responses import Response
from sqlalchemy.orm import Session

from app.database.base import get_db
from app.schemas.attendance import AttendanceCreate, AttendanceResponse
from app.schemas.sync import AttendanceBatchSyncRequest, AttendanceBatchSyncResponse
from app.services.attendance_service import AttendanceService
from app.api.v1.deps import get_current_user, require_admin, is_admin
from app.models.user import User

router = APIRouter(prefix="/attendance", tags=["Asistencia"])


@router.post("/", response_model=AttendanceResponse, status_code=201, summary="Registrar asistencia")
def register_attendance(
    data: AttendanceCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AttendanceResponse:
    """
    Register an attendance entry for the authenticated employee.

    The server decides `tipo` (entrada/salida) — never trust the client clock.
    Employees can only register for themselves; admins may register on behalf
    of any employee (e.g. an admin scanning for someone else).
    """
    # Enforce ownership server-side: non-admins cannot impersonate others.
    if not is_admin(current_user):
        data = data.model_copy(update={"usuario_id": current_user.id})
    return AttendanceService(db).register(data, background_tasks)


@router.post("/sync", response_model=AttendanceBatchSyncResponse, status_code=200, summary="Sincronizar lote de asistencias offline")
def sync_offline_attendance(
    payload: AttendanceBatchSyncRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AttendanceBatchSyncResponse:
    """
    Sincroniza un lote de asistencias capturadas localmente sin internet.

    Cada elemento incluye una `uuid_marca` única para garantizar idempotencia.
    Si el registro ya fue sincronizado anteriormente, el servidor lo ignora sin error.
    """
    records = payload.records
    if not is_admin(current_user):
        # Non-admins can only sync records with their own user id
        records = [
            r.model_copy(update={"usuario_id": current_user.id})
            for r in records
        ]
    return AttendanceService(db).sync_offline_batch(records, background_tasks)



@router.get("/", response_model=list[AttendanceResponse], summary="Listar todos los registros")
def list_attendance(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
) -> list[AttendanceResponse]:
    """Return paginated attendance records, newest first. Admins only."""
    return AttendanceService(db).get_all(skip=skip, limit=limit)


@router.get("/with-users", summary="Listar registros con datos de empleado")
def list_attendance_with_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(200, ge=1, le=1000),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
) -> list[dict]:
    """Return attendance records enriched with employee names. Admins only."""
    return AttendanceService(db).get_all_with_users(skip=skip, limit=limit)


@router.get("/user/{user_id}", response_model=list[AttendanceResponse], summary="Historial por empleado")
def list_by_user(
    user_id: int,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[AttendanceResponse]:
    """Return attendance history for a specific employee.
    Employees can only read their own history; admins can read anyone's."""
    if not is_admin(current_user) and user_id != current_user.id:
        raise HTTPException(status_code=403, detail="No tienes permiso para ver este historial.")
    return AttendanceService(db).get_by_user(user_id, skip=skip, limit=limit)


@router.get("/date/{fecha}", response_model=list[AttendanceResponse], summary="Registros por fecha")
def list_by_date(
    fecha: date,
    skip: int = Query(0, ge=0),
    limit: int = Query(200, ge=1, le=1000),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
) -> list[AttendanceResponse]:
    """Return all attendance records for a specific date (YYYY-MM-DD). Admins only."""
    return AttendanceService(db).get_by_date(fecha, skip=skip, limit=limit)


@router.get("/export/preview", summary="Preview de exportación")
def export_preview(
    fecha_desde: date | None = Query(None, description="Filtrar desde (YYYY-MM-DD)"),
    fecha_hasta: date | None = Query(None, description="Filtrar hasta (YYYY-MM-DD)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
) -> dict:
    """Retorna metadata + 20 sample rows para mostrar en el preview antes de exportar."""
    return AttendanceService(db).export_preview(
        fecha_desde=fecha_desde, fecha_hasta=fecha_hasta,
    )


@router.get("/export/excel", summary="Exportar asistencias a Excel o CSV")
def export_excel(
    fecha_desde: date | None = Query(None, description="Filtrar desde (YYYY-MM-DD)"),
    fecha_hasta: date | None = Query(None, description="Filtrar hasta (YYYY-MM-DD)"),
    formato: str = Query("xlsx", description="Formato: xlsx o csv"),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
) -> Response:
    """Export attendance history as Excel (.xlsx) or CSV. Admins only."""
    if formato == "csv":
        csv_bytes = AttendanceService(db).export_csv(
            fecha_desde=fecha_desde, fecha_hasta=fecha_hasta,
        )
        return Response(
            content=csv_bytes,
            media_type="text/csv",
            headers={"Content-Disposition": "attachment; filename=asistencias.csv"},
        )
    excel_bytes = AttendanceService(db).export_excel(
        fecha_desde=fecha_desde, fecha_hasta=fecha_hasta,
    )
    return Response(
        content=excel_bytes,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": "attachment; filename=asistencias.xlsx"},
    )


@router.get("/today-status", summary="Asistencia HOY de todos los empleados")
def today_status(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
) -> list[dict]:
    """Estado de asistencia de HOY para TODOS los empleados activos.
    Retorna nombre, cargo, foto, hora de entrada y si llegó a tiempo,
    tarde o no ha marcado. Ordenado: tarde primero, luego sin marcar,
    luego a tiempo. Incluye minutos de retraso. Admins only."""
    return AttendanceService(db).today_status()
