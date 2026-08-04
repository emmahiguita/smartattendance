# tests/test_attendance_sync.py
import pytest
from datetime import datetime, timezone
from fastapi.testclient import TestClient

from app.database.base import Base, engine, get_db, SessionLocal
from main import app
from app.models.user import User
from app.models.attendance import Attendance
from app.models.qr_code import QRCode
from app.core.security import create_access_token

@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    # Limpiar tablas previas de prueba
    db.query(Attendance).delete()
    db.query(QRCode).filter(QRCode.usuario_id.in_([1, 2, 99])).delete(synchronize_session=False)
    db.query(User).filter(User.id.in_([1, 2, 99])).delete()
    db.commit()

    admin_user = User(
        id=1,
        nombre="Admin",
        apellido="Test",
        cedula="999888777",
        correo="admin@test.com",
        cargo="Administrador",
        is_active=True,
    )
    emp_user = User(
        id=2,
        nombre="Empleado",
        apellido="Test",
        cedula="111222333",
        correo="emp@test.com",
        cargo="Desarrollador",
        is_active=True,
    )
    db.add(admin_user)
    db.add(emp_user)
    db.commit()
    db.close()
    yield

@pytest.fixture
def client():
    return TestClient(app)

@pytest.fixture
def admin_token():
    return create_access_token(data={"sub": "1"})

def test_register_single_attendance(client, admin_token):
    headers = {"Authorization": f"Bearer {admin_token}"}
    response = client.post(
        "/api/v1/attendance/",
        json={"usuario_id": 2, "tipo": "entrada"},
        headers=headers,
    )
    assert response.status_code == 201
    data = response.json()
    assert data["usuario_id"] == 2
    assert data["tipo"] == "entrada"

def test_batch_offline_sync_and_idempotency(client, admin_token):
    headers = {"Authorization": f"Bearer {admin_token}"}
    uuid1 = "uuid-test-001"
    uuid2 = "uuid-test-002"
    now_iso = datetime.now(timezone.utc).isoformat()

    payload = {
        "records": [
            {
                "uuid_marca": uuid1,
                "usuario_id": 2,
                "fecha_hora_local": now_iso,
                "tipo": "entrada",
                "latitud": 4.6097,
                "longitud": -74.0817,
                "direccion": "Bogotá, Colombia",
            },
            {
                "uuid_marca": uuid2,
                "usuario_id": 2,
                "fecha_hora_local": now_iso,
                "tipo": "salida_almuerzo",
            },
        ]
    }

    # 1. Enviar lote por primera vez
    response1 = client.post("/api/v1/attendance/sync", json=payload, headers=headers)
    assert response1.status_code == 200
    res1 = response1.json()
    assert res1["procesados"] == 2
    assert res1["ignorados_duplicados"] == 0
    assert res1["errores"] == 0

    # 2. Re-enviar exactamente el mismo lote (Simulando reintento de red)
    response2 = client.post("/api/v1/attendance/sync", json=payload, headers=headers)
    assert response2.status_code == 200
    res2 = response2.json()
    assert res2["procesados"] == 0
    assert res2["ignorados_duplicados"] == 2
    assert res2["errores"] == 0

def test_invalid_user_sync_graceful_handling(client, admin_token):
    headers = {"Authorization": f"Bearer {admin_token}"}
    now_iso = datetime.now(timezone.utc).isoformat()

    payload = {
        "records": [
            {
                "uuid_marca": "uuid-invalid-user",
                "usuario_id": 99999,  # Usuario que no existe
                "fecha_hora_local": now_iso,
                "tipo": "entrada",
            }
        ]
    }

    response = client.post("/api/v1/attendance/sync", json=payload, headers=headers)
    assert response.status_code == 200
    res = response.json()
    assert res["procesados"] == 0
    assert res["errores"] == 1
    assert res["detalles"][0]["status"] == "error_usuario_inactivo_o_no_encontrado"

def test_today_status_endpoint(client, admin_token):
    headers = {"Authorization": f"Bearer {admin_token}"}
    response = client.get("/api/v1/attendance/today-status", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 2


