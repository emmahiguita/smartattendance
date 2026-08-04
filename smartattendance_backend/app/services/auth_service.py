# app/services/auth_service.py
"""
Authentication service â€” login, registro pÃºblico, recuperaciÃ³n de contraseÃ±a
y renovaciÃ³n de tokens.
SRP: handles only authentication use cases.
DIP: depends on UserRepository abstraction, not SQLAlchemy directly.
"""
from sqlalchemy.orm import Session

from app.repositories.user_repository import UserRepository
from app.core.config import settings
from app.services.password_reset_service import password_reset_service
from app.core.hashing import hash_password, verify_password
from app.core.security import create_access_token, create_refresh_token, decode_refresh_token
from app.models.user import User
from app.schemas.user import (
    GoogleAuthRequest,
    LoginRequest,
    LoginResponse,
    RefreshRequest,
    RefreshResponse,
    RegisterRequest,
    ResetPasswordRequest,
    ResetPasswordResponse,
    UserResponse,
)
from fastapi import HTTPException, status


class AuthService:
    """Autentica por cÃ©dula (+contraseÃ±a si la cuenta tiene), registra y renueva tokens."""

    def __init__(self, db: Session) -> None:
        self._db = db
        self._repo = UserRepository(db)

    def login(self, request: LoginRequest) -> LoginResponse:
        """Valida cÃ©dula (y contraseÃ±a si la cuenta tiene una) y emite tokens."""
        user = self._repo.get_by_cedula(request.cedula)

        if user is None or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="CÃ©dula no encontrada o usuario inactivo.",
            )

        # Si la cuenta tiene contraseÃ±a, se exige SIEMPRE.
        if user.hashed_password:
            if not request.password or not verify_password(request.password, user.hashed_password):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="ContraseÃ±a incorrecta.",
                )

        return self._issue_tokens(user)

    def register(self, request: RegisterRequest) -> LoginResponse:
        """Auto-registro pÃºblico: crea la cuenta con contraseÃ±a y emite tokens (login automÃ¡tico)."""
        if self._repo.get_by_cedula(request.cedula) is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="La cÃ©dula ya estÃ¡ registrada. Inicia sesiÃ³n o recupera tu contraseÃ±a.",
            )
        if self._repo.get_by_correo(str(request.correo)) is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="El correo electrÃ³nico ya estÃ¡ registrado.",
            )

        user = User(
            nombre=request.nombre,
            apellido=request.apellido,
            cedula=request.cedula,
            correo=str(request.correo),
            cargo=request.cargo.strip() or "Empleado",
            telefono=request.telefono,
            fecha_nacimiento=request.fecha_nacimiento,
            hashed_password=hash_password(request.password),
        )
        self._db.add(user)
        self._db.commit()
        self._db.refresh(user)

        return self._issue_tokens(user)

    def reset_password(self, request: ResetPasswordRequest) -> ResetPasswordResponse:
        password_reset_service.verify_code(request.cedula, str(request.correo), request.code)
        """RecuperaciÃ³n sin SMTP: la identidad se verifica con cÃ©dula + correo registrado.
        Mismo mensaje genÃ©rico si cÃ©dula o correo no coinciden â€” no filtra cuÃ¡l fallÃ³."""
        user = self._repo.get_by_cedula(request.cedula)

        if (
            user is None
            or not user.is_active
            or user.correo.strip().lower() != str(request.correo).strip().lower()
        ):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Los datos no coinciden con ninguna cuenta registrada.",
            )

        user.hashed_password = hash_password(request.new_password)
        self._db.add(user)
        self._db.commit()

        return ResetPasswordResponse(
            mensaje="ContraseÃ±a actualizada correctamente. Ya puedes iniciar sesiÃ³n."
        )

    def refresh(self, request: RefreshRequest) -> RefreshResponse:
        """Validate a refresh token and issue a fresh access token (rotated refresh)."""
        payload = decode_refresh_token(request.refresh_token)

        try:
            user_id = int(payload["sub"])
        except (KeyError, TypeError, ValueError):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token de refresco invÃ¡lido.",
            )

        user = self._repo.get_by_id(user_id)
        if user is None or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="El usuario del token no existe o estÃ¡ inactivo.",
            )

        return RefreshResponse(
            access_token=create_access_token({"sub": str(user.id), "cedula": user.cedula}),
            refresh_token=create_refresh_token({"sub": str(user.id)}),
        )

    def google_login(self, request: GoogleAuthRequest) -> LoginResponse:
        """Inicio de sesiÃ³n con Google.

        El id_token se verifica CRIPTOGRÃFICAMENTE contra Google (aud = nuestro
        client ID). La cuenta debe existir en el sistema de asistencia (bÃºsqueda
        por correo): no se auto-registra sin cÃ©dula â€” la cÃ©dula es la identidad
        de nÃ³mina y debe asignarla un administrador.
        """
        if not settings.GOOGLE_CLIENT_ID:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Google Sign-In no estÃ¡ configurado en el servidor. "
                "Contacta al administrador.",
            )

        try:
            from google.auth.transport import requests as google_requests
            from google.oauth2 import id_token as google_id_token

            info = google_id_token.verify_oauth2_token(
                request.id_token,
                google_requests.Request(),
                settings.GOOGLE_CLIENT_ID,
            )
        except ValueError:
            # Token invÃ¡lido, expirado o de otra audiencia.
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token de Google invÃ¡lido o expirado.",
            )
        except Exception as e:  # noqa: BLE001 â€” fallo de red al verificar con Google
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="No se pudo verificar la identidad con Google.",
            )

        email = info.get("email")
        if not email:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="La cuenta de Google no tiene correo asociado.",
            )

        user = self._repo.get_by_correo(email.strip().lower())
        if user is None or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=(
                    "No existe una cuenta de asistencia vinculada a este correo. "
                    "Pide a tu administrador que te registre."
                ),
            )

        return self._issue_tokens(user)

    def _issue_tokens(self, user: User) -> LoginResponse:
        return LoginResponse(
            access_token=create_access_token({"sub": str(user.id), "cedula": user.cedula}),
            refresh_token=create_refresh_token({"sub": str(user.id)}),
            user=UserResponse.model_validate(user),
        )



