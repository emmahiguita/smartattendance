# app/core/config.py
"""
Application settings via pydantic-settings.
SRP: single place for all environment/config values.
OCP: extend with new fields without modifying existing callers.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    # App
    APP_NAME: str = "SmartAttendance API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    # Database
    DATABASE_URL: str = "sqlite:///./smartattendance.db"
    DB_ECHO: bool = False
    DB_POOL_SIZE: int = 10
    DB_MAX_OVERFLOW: int = 20
    DB_POOL_TIMEOUT_SECONDS: int = 30
    DB_POOL_RECYCLE_SECONDS: int = 1800
    DB_CONNECT_TIMEOUT_SECONDS: int = 10
    SQLITE_BUSY_TIMEOUT_MS: int = 5000

    # Security
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 hours
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30  # refresh token lifetime

    # Google Sign-In Ã¢â‚¬â€ client ID del proyecto OAuth (web/server) de Google Cloud.
    # VacÃ­o Ã¢â€¡â€™ el endpoint /auth/google responde 503 con mensaje claro.
    GOOGLE_CLIENT_ID: str = ""

    # Zona horaria del NEGOCIO (paÃ­s de la empresa). Todas las marcas de
    # asistencia se registran en ESTA zona, independiente de dÃ³nde corra el
    # servidor. Colombia = UTC-5.
    TIMEZONE: str = "America/Bogota"

    # Hora lÃ­mite de entrada Ã¢â‚¬â€ despuÃ©s de esta hora, el empleado se marca
    # como "tarde" en el panel de asistencia del dÃ­a.
    HORA_ENTRADA_LIMITE: str = "08:30"

    # Browser origins only. Mobile Flutter clients do not require CORS.
    ALLOWED_ORIGINS: list[str] = []

    # SMTP for out-of-band password-reset OTP delivery.
    SMTP_HOST: str = ""
    SMTP_PORT: int = 587
    SMTP_USERNAME: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_FROM: str = ""
    SMTP_USE_TLS: bool = True



settings = Settings()





