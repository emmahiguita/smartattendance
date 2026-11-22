# tests/test_crews_and_photo_mark.py
"""
Tests for Crews, Work Zones, and Biometric Photo Attendance Mark.
"""
import pytest
import io
from fastapi.testclient import TestClient

from app.database.base import SessionLocal, create_all_tables
from main import app
from app.models.user import User
from app.models.crew import Crew, WorkZone, CrewPosition
from app.models.attendance import Attendance
from app.core.security import create_access_token


@pytest.fixture(autouse=True)
def setup_db():
    create_all_tables()
    db = SessionLocal()
    db.query(Attendance).delete()
    db.query(CrewPosition).delete()
    db.query(Crew).delete()
    db.query(WorkZone).delete()
    db.query(User).filter(User.id.in_([10, 11])).delete()
    db.commit()

    admin = User(
        id=10,
        nombre="Super",
        apellido="Admin",
        cedula="1007331963",
        correo="admin@serviciudad.gov.co",
        cargo="Administrador",
        is_active=True,
    )
    supervisor = User(
        id=11,
        nombre="Supervisor",
        apellido="Redes",
        cedula="1088236000",
        correo="supervisor@serviciudad.gov.co",
        cargo="Supervisor",
        is_active=True,
    )
    db.add(admin)
    db.add(supervisor)
    db.commit()
    db.close()
    yield


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def admin_token():
    return create_access_token(data={"sub": "10"})


@pytest.fixture
def supervisor_token():
    return create_access_token(data={"sub": "11"})


def test_work_zone_and_crew_crud(client, admin_token, supervisor_token):
    admin_headers = {"Authorization": f"Bearer {admin_token}"}
    sup_headers = {"Authorization": f"Bearer {supervisor_token}"}

    # 1. Admin crea geocerca
    zone_payload = {
        "name": "Planta Tratamiento El Tambo",
        "latitude": 4.8155,
        "longitude": -75.6944,
        "radius_m": 120.0,
        "address": "Vía El Tambo Km 3",
    }
    r_zone = client.post("/api/v1/zones", json=zone_payload, headers=admin_headers)
    assert r_zone.status_code == 201
    zone = r_zone.json()
    assert zone["name"] == "Planta Tratamiento El Tambo"
    zone_id = zone["id"]

    # 2. Supervisor lista geocercas
    r_list_zones = client.get("/api/v1/zones", headers=sup_headers)
    assert r_list_zones.status_code == 200
    assert len(r_list_zones.json()) >= 1

    # 3. Supervisor crea cuadrilla asignada a su cédula con puestos
    crew_payload = {
        "name": "Cuadrilla Nocturna Redes",
        "supervisor_document": "1088236000",
        "driver_document": "1088236999",
        "zone_id": zone_id,
        "valid_from": "2026-11-18",
        "valid_until": "2026-12-31",
        "positions": ["Operador Fontanería", "Ayudante Redes"],
    }
    r_crew = client.post("/api/v1/crews", json=crew_payload, headers=sup_headers)
    assert r_crew.status_code == 201
    crew = r_crew.json()
    assert crew["name"] == "Cuadrilla Nocturna Redes"
    assert len(crew["positions"]) == 2

    # 4. Supervisor no puede crear cuadrilla con cédula ajena
    crew_invalid = {
        "name": "Cuadrilla Ilegal",
        "supervisor_document": "999999999",
        "valid_from": "2026-11-18",
        "valid_until": "2026-12-31",
    }
    r_invalid = client.post("/api/v1/crews", json=crew_invalid, headers=sup_headers)
    assert r_invalid.status_code == 403


def test_photo_mark_endpoint_with_image(client, admin_token):
    headers = {"Authorization": f"Bearer {admin_token}"}
    fake_image = io.BytesIO(b"\xff\xd8\xff\xe0\x00\x10JFIF" + b"\x00" * 50)

    uuid_val = "uuid-biometric-test-1234"
    params = {
        "cedula": "1088236000",
        "tipo": "entrada",
        "uuid_marca": uuid_val,
        "latitud": 4.8155,
        "longitud": -75.6944,
        "direccion": "Sede Central Serviciudad",
    }
    files = {"foto": ("evidencia.jpg", fake_image, "image/jpeg")}

    # 1. Enviar marcación con foto
    response = client.post("/api/v1/attendance/photo-mark", params=params, files=files, headers=headers)
    assert response.status_code == 201
    data = response.json()
    assert data["uuid_marca"] == uuid_val
    assert data["tipo"] == "entrada"
    assert data["foto_url"] == f"/static/attendance_photos/{uuid_val}.jpg"

    # 2. Idempotencia: re-enviar la misma marca no la duplica
    response2 = client.post("/api/v1/attendance/photo-mark", params=params, files=files, headers=headers)
    assert response2.status_code == 201
    assert response2.json()["uuid_marca"] == uuid_val
