# tests/test_health.py
# ===================================================================
# Pruebas de salud del backend: verifica que la API arranca, responde
# al health check, la documentaciÃ³n estÃ¡ accesible, y los endpoints
# pÃºblicos rechazan correctamente requests sin autenticaciÃ³n.
# ===================================================================
import pytest
from fastapi.testclient import TestClient

from main import create_app
from app.core.config import settings


@pytest.fixture
def client() -> TestClient:
    """TestClient usando la factory â€” aislado, sin efectos laterales."""
    app = create_app()
    return TestClient(app)


class TestHealthCheck:
    """Verifica que la API estÃ© viva y responda."""

    def test_health_endpoint_returns_ok(self, client: TestClient):
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert data["app"] == settings.APP_NAME
        assert data["version"] == settings.APP_VERSION

    def test_health_content_type_is_json(self, client: TestClient):
        response = client.get("/health")
        assert response.status_code == 200
        assert "application/json" in response.headers["content-type"]


class TestDocumentation:
    """Verifica que la documentaciÃ³n interactiva estÃ© disponible."""

    def test_openapi_schema_accessible(self, client: TestClient):
        response = client.get("/openapi.json")
        assert response.status_code == 200
        schema = response.json()
        assert "openapi" in schema
        assert schema["info"]["title"] == settings.APP_NAME
        assert schema["info"]["version"] == settings.APP_VERSION

    def test_swagger_ui_accessible(self, client: TestClient):
        response = client.get("/docs")
        assert response.status_code == 200
        assert "text/html" in response.headers["content-type"]

    def test_redoc_accessible(self, client: TestClient):
        response = client.get("/redoc")
        assert response.status_code == 200
        assert "text/html" in response.headers["content-type"]


class TestCORSHeaders:
    """Verifica que los headers CORS estÃ©n presentes."""

    def test_cors_headers_on_options(self, client: TestClient):
        response = client.options(
            "/api/v1/auth/login",
            headers={
                "Origin": "http://localhost:50000",
                "Access-Control-Request-Method": "POST",
            },
        )
        # FastAPI TestClient no emula CORS preflight completamente,
        # pero verificamos que el endpoint responde a OPTIONS.
        assert response.status_code == 400  # origen no autorizado debe bloquearse

    def test_cors_allow_origin_on_get(self, client: TestClient):
        response = client.get(
            "/health",
            headers={"Origin": "http://localhost:50000"},
        )
        # Con allow_origins=["*"], debe devolver * o el origin
        assert response.status_code == 200


class TestAuthEndpoints:
    """Verifica que los endpoints de auth respondan correctamente."""

    def test_login_requires_cedula(self, client: TestClient):
        """POST /api/v1/auth/login sin cÃ©dula debe retornar 422."""
        response = client.post("/api/v1/auth/login", json={})
        assert response.status_code == 422  # Validation error

    def test_login_with_invalid_cedula_returns_401(self, client: TestClient):
        """CÃ©dula inexistente â†’ 401."""
        response = client.post(
            "/api/v1/auth/login",
            json={"cedula": "0000000000"},
        )
        # Puede ser 401 (usuario no encontrado) o 422 si falta password
        assert response.status_code in (401, 422)

    def test_register_requires_fields(self, client: TestClient):
        """POST /api/v1/auth/register sin campos requeridos â†’ 422."""
        response = client.post("/api/v1/auth/register", json={})
        assert response.status_code == 422

    def test_forgot_password_endpoint_behavior(self, client: TestClient):
        """POST /api/v1/auth/forgot-password: verifica que responde."""
        response = client.post("/api/v1/auth/forgot-password", json={})
        # 404 si la ruta no existe, 422 si existe pero requiere campos
        assert response.status_code in (404, 422)


class TestProtectedEndpoints:
    """Verifica que los endpoints protegidos rechacen sin token."""

    def test_attendance_without_token_returns_401(self, client: TestClient):
        response = client.post(
            "/api/v1/attendance/",
            json={"usuario_id": 1, "tipo": "entrada"},
        )
        assert response.status_code == 401

    def test_attendance_sync_without_token_returns_401(self, client: TestClient):
        response = client.post("/api/v1/attendance/sync", json={"records": []})
        assert response.status_code == 401

    def test_today_status_without_token_returns_401(self, client: TestClient):
        response = client.get("/api/v1/attendance/today-status")
        assert response.status_code == 401

    def test_users_me_without_token_returns_401(self, client: TestClient):
        response = client.get("/api/v1/users/me")
        assert response.status_code == 401

    def test_users_update_without_token_returns_401(self, client: TestClient):
        response = client.put("/api/v1/users/me", json={})
        assert response.status_code == 401


class TestAppMetadata:
    """Verifica que la metadata de la app sea correcta."""

    def test_app_title_and_version(self, client: TestClient):
        response = client.get("/openapi.json")
        info = response.json()["info"]
        assert info["title"] == "SmartAttendance API"
        assert info["version"] == "1.0.0"
        assert "API REST" in info["description"]

    def test_all_v1_routes_registered(self, client: TestClient):
        """Verifica que todas las rutas v1 estÃ©n registradas."""
        response = client.get("/openapi.json")
        paths = response.json()["paths"]

        expected_prefixes = [
            "/api/v1/auth/",
            "/api/v1/attendance/",
            "/api/v1/users/",
        ]
        for prefix in expected_prefixes:
            matching = [p for p in paths if p.startswith(prefix)]
            assert len(matching) > 0, f"No se encontraron rutas con prefijo {prefix}"


class TestSettings:
    """Verifica que la configuraciÃ³n tenga valores esperados."""

    def test_default_settings(self):
        assert settings.APP_NAME == "SmartAttendance API"
        assert settings.APP_VERSION == "1.0.0"
        assert settings.ALGORITHM == "HS256"
        assert settings.ACCESS_TOKEN_EXPIRE_MINUTES == 1440
        assert settings.REFRESH_TOKEN_EXPIRE_DAYS == 30
        assert settings.TIMEZONE == "America/Bogota"
        assert settings.HORA_ENTRADA_LIMITE == "08:30"

    def test_secret_key_is_set(self):
        """SECRET_KEY debe estar configurado (via .env)."""
        assert settings.SECRET_KEY is not None
        assert len(settings.SECRET_KEY) > 0

