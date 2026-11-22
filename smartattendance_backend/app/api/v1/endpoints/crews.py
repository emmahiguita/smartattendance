# app/api/v1/endpoints/crews.py
"""
Crews & Work Zones endpoints — CRUD and synchronization for field operations.
"""
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database.base import get_db
from app.models.crew import Crew, WorkZone, CrewPosition
from app.models.user import User
from app.schemas.crew import (
    CrewCreate,
    CrewResponse,
    WorkZoneCreate,
    WorkZoneResponse,
)
from app.api.v1.deps import get_current_user, require_admin, is_admin

router = APIRouter(tags=["Cuadrillas y Geocercas"])


# ── GEOCERCAS / WORK ZONES ──────────────────────────────────────────

@router.get("/zones", response_model=list[WorkZoneResponse], summary="Listar geocercas operativas")
def list_zones(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[WorkZoneResponse]:
    """Retorna todas las geocercas configuradas para cuadrillas."""
    return db.query(WorkZone).order_by(WorkZone.name.asc()).all()


@router.post("/zones", response_model=WorkZoneResponse, status_code=201, summary="Crear geocerca operativa")
def create_zone(
    data: WorkZoneCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
) -> WorkZoneResponse:
    """Crea una nueva zona de trabajo con radio GPS. Solo Administradores."""
    zone = WorkZone(**data.model_dump())
    db.add(zone)
    db.commit()
    db.refresh(zone)
    return zone


# ── CUADRILLAS / CREWS ──────────────────────────────────────────────

@router.get("/crews", response_model=list[CrewResponse], summary="Listar cuadrillas")
def list_crews(
    supervisor_document: str | None = Query(None, description="Filtrar por supervisor"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[CrewResponse]:
    """Retorna las cuadrillas registradas. Los supervisores solo ven sus cuadrillas."""
    query = db.query(Crew)
    if not is_admin(current_user):
        query = query.filter(Crew.supervisor_document == current_user.cedula)
    elif supervisor_document:
        query = query.filter(Crew.supervisor_document == supervisor_document)

    return query.order_by(Crew.id.desc()).all()


@router.post("/crews", response_model=CrewResponse, status_code=201, summary="Crear cuadrilla y puestos")
def create_crew(
    data: CrewCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> CrewResponse:
    """Crea una cuadrilla con sus puestos autorizados. Admins y Supervisores."""
    if not is_admin(current_user) and data.supervisor_document != current_user.cedula:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Un supervisor solo puede crear cuadrillas asignadas a su propia cédula.",
        )

    crew_data = data.model_dump(exclude={"positions"})
    crew = Crew(**crew_data)
    db.add(crew)
    db.commit()
    db.refresh(crew)

    for pos_title in data.positions:
        clean_title = pos_title.trim() if hasattr(pos_title, 'trim') else pos_title.strip()
        if clean_title:
            pos = CrewPosition(crew_id=crew.id, title=clean_title)
            db.add(pos)

    db.commit()
    db.refresh(crew)
    return crew
