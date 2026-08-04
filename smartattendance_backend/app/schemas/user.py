# app/schemas/user.py
"""
Pydantic schemas for User â€” request/response contracts.
ISP: separate schemas per use case (Create, Response, Login).
"""
from datetime import datetime
from pydantic import BaseModel, EmailStr, field_validator


class UserCreate(BaseModel):
    nombre: str
    apellido: str
    cedula: str
    correo: EmailStr
    cargo: str
    fecha_nacimiento: str | None = None
    telefono: str | None = None
    direccion: str | None = None

    @field_validator("cedula")
    @classmethod
    def cedula_must_be_numeric(cls, v: str) -> str:
        if not v.strip().isdigit():
            raise ValueError("La cÃ©dula debe contener solo dÃ­gitos")
        return v.strip()


class UserResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: int
    nombre: str
    apellido: str
    cedula: str
    correo: str
    cargo: str
    fecha_nacimiento: str | None = None
    telefono: str | None = None
    direccion: str | None = None
    is_active: bool
    created_at: datetime
    foto_url: str | None = None

    @property
    def full_name(self) -> str:
        return f"{self.nombre} {self.apellido}"


class UserUpdate(BaseModel):
    """Campos editables del perfil â€” todos opcionales."""
    nombre: str | None = None
    apellido: str | None = None
    correo: EmailStr | None = None
    fecha_nacimiento: str | None = None
    telefono: str | None = None
    direccion: str | None = None
    foto_url: str | None = None

    @field_validator("nombre", "apellido")
    @classmethod
    def not_blank(cls, v: str | None) -> str | None:
        if v is not None and not v.strip():
            raise ValueError("No puede estar vacÃ­o")
        return v.strip() if v else v


class LoginRequest(BaseModel):
    cedula: str
    # Opcional: cuentas creadas por un admin pueden no tener contraseÃ±a aÃºn.
    # Si la cuenta TIENE contraseÃ±a, el servidor la exige siempre.
    password: str | None = None

    @field_validator("cedula")
    @classmethod
    def cedula_strip(cls, v: str) -> str:
        return v.strip()


class RegisterRequest(BaseModel):
    """Auto-registro pÃºblico de empleado con contraseÃ±a."""
    nombre: str
    apellido: str
    cedula: str
    correo: EmailStr
    password: str
    telefono: str | None = None
    cargo: str = "Empleado"
    fecha_nacimiento: str | None = None  # YYYY-MM-DD

    @field_validator("cedula")
    @classmethod
    def cedula_must_be_numeric(cls, v: str) -> str:
        if not v.strip().isdigit():
            raise ValueError("La cÃ©dula debe contener solo dÃ­gitos")
        return v.strip()

    @field_validator("password")
    @classmethod
    def password_complexity(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("La contraseÃ±a debe tener al menos 8 caracteres")
        if not any(c.isupper() for c in v):
            raise ValueError("La contraseÃ±a requiere al menos una letra mayÃºscula")
        if not any(c.islower() for c in v):
            raise ValueError("La contraseÃ±a requiere al menos una letra minÃºscula")
        if not any(c.isdigit() for c in v):
            raise ValueError("La contraseÃ±a requiere al menos un nÃºmero")
        return v

    @field_validator("nombre", "apellido")
    @classmethod
    def not_blank(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("No puede estar vacÃ­o")
        return v.strip()


class PasswordResetCodeRequest(BaseModel):
    cedula: str
    correo: EmailStr


class ResetPasswordRequest(BaseModel):
    """RecuperaciÃ³n sin SMTP: identidad verificada con cÃ©dula + correo registrado."""
    cedula: str
    correo: EmailStr
    new_password: str
    code: str

    @field_validator("cedula")
    @classmethod
    def cedula_strip(cls, v: str) -> str:
        return v.strip()

    @field_validator("new_password")
    @classmethod
    def password_complexity(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("La contraseÃ±a debe tener al menos 8 caracteres")
        if not any(c.isupper() for c in v):
            raise ValueError("La contraseÃ±a requiere al menos una letra mayÃºscula")
        if not any(c.islower() for c in v):
            raise ValueError("La contraseÃ±a requiere al menos una letra minÃºscula")
        if not any(c.isdigit() for c in v):
            raise ValueError("La contraseÃ±a requiere al menos un nÃºmero")
        return v


class ResetPasswordResponse(BaseModel):
    mensaje: str


class LoginResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse


class RefreshRequest(BaseModel):
    refresh_token: str


class GoogleAuthRequest(BaseModel):
    """Inicio de sesiÃ³n con Google: el id_token verificado por Google."""
    id_token: str


class RefreshResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"



