# main.py
"""
SmartAttendance FastAPI application entry point.
SRP: only application factory and startup configuration live here.
"""
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.config import settings
from app.api.v1.router import api_v1_router
from app.database.base import create_all_tables
from app.core.rate_limit import rate_limiter


@asynccontextmanager
async def lifespan(app: FastAPI):
    create_all_tables()
    yield


def create_app() -> FastAPI:
    """Application factory â€” OCP: extend by calling include_router without modifying here."""
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        description=(
            "API REST para el sistema de control de asistencia SmartAttendance. "
            "Construida con FastAPI, SQLAlchemy y Clean Architecture."
        ),
        docs_url="/docs",
        redoc_url="/redoc",
        lifespan=lifespan,
    )

    # CORS â€” allows Flutter mobile app connections
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.middleware("http")
    async def limit_public_auth(request: Request, call_next):
        if request.url.path.startswith("/api/v1/auth/"):
            client_ip = request.client.host if request.client else "unknown"
            if not rate_limiter.allow(f"auth:{client_ip}", limit=5, window_seconds=60):
                return JSONResponse(status_code=429, content={"detail": "Demasiados intentos. Intenta de nuevo en un minuto."}, headers={"Retry-After": "60"})
        return await call_next(request)

    # Routers
    app.include_router(api_v1_router)

    # Fotos de perfil
    static_dir = Path(__file__).parent / "static"
    static_dir.mkdir(exist_ok=True)
    (static_dir / "fotos").mkdir(exist_ok=True)
    app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")

    # Health check
    @app.get("/health", tags=["Sistema"], summary="Estado del servidor")
    async def health_check() -> dict:
        return {"status": "ok", "app": settings.APP_NAME, "version": settings.APP_VERSION}

    return app


app = create_app()

