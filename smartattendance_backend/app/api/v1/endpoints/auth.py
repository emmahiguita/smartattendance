# app/api/v1/endpoints/auth.py
"""
Auth endpoints â€” login, registro pÃºblico, recuperaciÃ³n de contraseÃ±a y refresh.
SRP: router delegates all logic to AuthService.
"""
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database.base import get_db
from app.schemas.user import (
    GoogleAuthRequest,
    LoginRequest,
    LoginResponse,
    RefreshRequest,
    RefreshResponse,
    RegisterRequest,
    ResetPasswordRequest,
    ResetPasswordResponse,
)
from app.services.auth_service import AuthService
from app.services.password_reset_service import password_reset_service

router = APIRouter(prefix="/auth", tags=["AutenticaciÃ³n"])


@router.post("/login", response_model=LoginResponse, summary="Iniciar sesiÃ³n")
def login(request: LoginRequest, db: Session = Depends(get_db)) -> LoginResponse:
    """
    Authenticate an employee by cÃ©dula. If the account has a password set,
    it is always required. Returns JWT access + refresh tokens and user info.
    """
    return AuthService(db).login(request)


@router.post(
    "/register",
    response_model=LoginResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registro pÃºblico de empleado",
)
def register(request: RegisterRequest, db: Session = Depends(get_db)) -> LoginResponse:
    """
    Public self-registration with password. Creates the account and returns
    tokens (automatic login). CÃ©dula and correo must be unique.
    """
    return AuthService(db).register(request)


@router.post("/reset-password/request", response_model=ResetPasswordResponse)
def request_password_reset(request: PasswordResetCodeRequest, db: Session = Depends(get_db)) -> ResetPasswordResponse:
    user = AuthService(db)._repo.get_by_cedula(request.cedula)
    if user and user.is_active and user.correo.strip().lower() == str(request.correo).strip().lower():
        password_reset_service.request_code(request.cedula, str(request.correo))
    return ResetPasswordResponse(mensaje="Si los datos coinciden, enviamos un código al correo registrado.")

@router.post("/reset-password", response_model=ResetPasswordResponse, summary="Recuperar contraseÃ±a")
def reset_password(request: ResetPasswordRequest, db: Session = Depends(get_db)) -> ResetPasswordResponse:
    """
    Password recovery without email delivery: identity is verified by matching
    cÃ©dula + registered correo. On success the new password is stored (bcrypt).
    """
    return AuthService(db).reset_password(request)


@router.post("/refresh", response_model=RefreshResponse, summary="Renovar token de acceso")
def refresh(request: RefreshRequest, db: Session = Depends(get_db)) -> RefreshResponse:
    """
    Exchange a valid refresh token for a new access token.
    The refresh token is rotated (a new one is issued).
    """
    return AuthService(db).refresh(request)


@router.post("/google", response_model=LoginResponse, summary="Iniciar sesiÃ³n con Google")
def google_login(request: GoogleAuthRequest, db: Session = Depends(get_db)) -> LoginResponse:
    """
    Authenticate with a Google ID token (verified server-side against the
    configured OAuth client). The Google account must be linked to an existing
    attendance account by email.
    """
    return AuthService(db).google_login(request)


