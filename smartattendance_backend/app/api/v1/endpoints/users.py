# app/api/v1/endpoints/users.py
"""
Users endpoints â€” list and manage employees.
SRP: router delegates all logic to repository.
"""
import os
import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File, status
from sqlalchemy.orm import Session

from app.database.base import get_db
from app.schemas.user import (
    UserCreate,
    UserResponse,
    UserUpdate,
    ProfileBatchSyncRequest,
    ProfileBatchSyncResponse,
)
from app.repositories.user_repository import UserRepository
from app.api.v1.deps import get_current_user, require_admin
from app.models.user import User

router = APIRouter(prefix="/users", tags=["Empleados"])


@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED, summary="Registrar nuevo empleado")
def create_user(
    data: UserCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
) -> UserResponse:
    """Register/create a new employee with full profile details. Admins only."""
    repo = UserRepository(db)

    # Validar cÃ©dula Ãºnica
    if repo.get_by_cedula(data.cedula) is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="La cÃ©dula ya estÃ¡ registrada para otro empleado.",
        )

    # Validar correo Ãºnico
    if repo.get_by_correo(data.correo) is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El correo electrÃ³nico ya estÃ¡ registrado.",
        )

    user = repo.create(data)
    return UserResponse.model_validate(user)


@router.get("/", response_model=list[UserResponse], summary="Listar empleados activos")
def list_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
) -> list[UserResponse]:
    """Return all active employees. Admins only."""
    repo = UserRepository(db)
    users = repo.list_all(skip=skip, limit=limit)
    return [UserResponse.model_validate(u) for u in users]


@router.get("/me", response_model=UserResponse, summary="Datos del usuario actual")
def get_me(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    """Return the authenticated user's own data."""
    return UserResponse.model_validate(current_user)


@router.put("/me", response_model=UserResponse, summary="Actualizar mi perfil")
def update_me(
    data: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    """Update the authenticated user's own profile (nombre, apellido, correo, fecha_nacimiento, telefono, direccion)."""
    repo = UserRepository(db)

    if data.correo is not None:
        # Evitar duplicados de correo (a menos que sea el mismo usuario)
        existing = repo.get_by_correo(data.correo)
        if existing is not None and existing.id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="El correo ya estÃ¡ en uso por otro empleado.",
            )

    updated = repo.update(current_user, data.model_dump(exclude_unset=True))
    return UserResponse.model_validate(updated)


# â”€â”€ FOTO DE PERFIL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
FOTOS_DIR = Path(__file__).resolve().parent.parent.parent.parent / "static" / "fotos"
FOTOS_DIR.mkdir(parents=True, exist_ok=True)


def _detect_image_format(content: bytes) -> str | None:
    if content.startswith(b"\xff\xd8\xff"):
        return "jpeg"
    if content.startswith(b"\x89PNG\r\n\x1a\n"):
        return "png"
    if content.startswith(b"RIFF") and len(content) >= 12 and content[8:12] == b"WEBP":
        return "webp"
    return None


@router.put("/me/foto", response_model=UserResponse, summary="Subir foto de perfil")
async def upload_foto(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    """Sube una foto de perfil (JPEG/PNG, mÃ¡x 2MB). Reemplaza la anterior."""
    if file.content_type not in ("image/jpeg", "image/png", "image/webp"):
        raise HTTPException(status_code=400, detail="Solo imÃ¡genes JPEG, PNG o WebP.")

    content = await file.read()
    if len(content) > 2 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="La imagen no puede superar 2MB.")

    detected_format = _detect_image_format(content)
    expected_format = {"image/jpeg": "jpeg", "image/png": "png", "image/webp": "webp"}[file.content_type]
    if detected_format != expected_format:
        raise HTTPException(status_code=400, detail="El contenido no coincide con el tipo de imagen declarado.")
    ext = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}[file.content_type]
    filename = f"{current_user.id}_{uuid.uuid4().hex[:8]}{ext}"
    filepath = FOTOS_DIR / filename
    filepath.write_bytes(content)

    # Eliminar la foto anterior si existe
    if current_user.foto_url:
        old = FOTOS_DIR / Path(current_user.foto_url).name
        if old.exists():
            old.unlink(missing_ok=True)

    repo = UserRepository(db)
    updated = repo.update(current_user, {"foto_url": f"/static/fotos/{filename}"})
    return UserResponse.model_validate(updated)


# ── SYNC DE PERFIL OFFLINE ────────────────────────────────────────────

# Profile sync schemas imported from app.schemas.user
@router.post("/me/sync", response_model=ProfileBatchSyncResponse, status_code=200,
             summary="Sincronizar cambios de perfil offline")
def sync_profile(
    payload: ProfileBatchSyncRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ProfileBatchSyncResponse:
    """Aplica cambios de perfil guardados offline y retorna resultados."""
    procesados = 0
    errores = 0
    detalles = []
    seen: set[int] = set()
    repo = UserRepository(db)

    for item in payload.changes:
        cid = item.client_id
        if cid in seen:
            detalles.append({"client_id": cid, "status": "duplicado_ignorado"})
            continue
        seen.add(cid)

        try:
            changes = item.changes
            # Solo permitir campos seguros
            allowed = {"nombre", "apellido", "correo", "fecha_nacimiento",
                       "telefono", "direccion"}
            safe = {k: v for k, v in changes.items() if k in allowed}
            if not safe:
                errores += 1
                detalles.append({"client_id": cid, "status": "error_empty"})
                continue

            repo.update(current_user, safe)
            procesados += 1
            detalles.append({"client_id": cid, "status": "creado"})
        except Exception as e:
            errores += 1
            detalles.append({"client_id": cid, "status": "error",
                             "mensaje": str(e)})

    return ProfileBatchSyncResponse(
        procesados=procesados, errores=errores, detalles=detalles,
    )

