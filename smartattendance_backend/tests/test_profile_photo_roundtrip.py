"""Subir y leer la misma fotografía debe usar el mismo almacén físico.

Prueba de integración local con SQLite temporal, fichero real y API ASGI.
La identidad se inyecta para aislar almacenamiento; no prueba inicio de sesión.
"""
import base64
from pathlib import Path
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool
from app.database.base import Base, get_db
from app.api.v1.deps import get_current_user
from app.api.v1.endpoints import users
from app.models.user import User
from main import create_app


def test_uploaded_photo_url_returns_the_stored_bytes():
    engine = create_engine('sqlite://', poolclass=StaticPool,
                           connect_args={'check_same_thread': False})
    Base.metadata.create_all(engine)
    picture = base64.b64decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6aeYAAAAASUVORK5CYII=')
    stored_path = None
    with Session(engine) as db:
        user = User(nombre='QA', apellido='Foto', cedula='QA-PHOTO',
                    correo='qa-photo@example.com', cargo='Empleado')
        db.add(user); db.commit(); db.refresh(user)
        app = create_app()
        app.dependency_overrides[get_db] = lambda: db
        app.dependency_overrides[get_current_user] = lambda: user
        # Sin lifespan: nunca ejecuta migraciones ni seed de la base del equipo.
        client = TestClient(app)
        try:
            uploaded = client.put('/api/v1/users/me/foto',
                files={'file': ('qa.png', picture, 'image/png')})
            assert uploaded.status_code == 200
            url = uploaded.json()['foto_url']
            stored_path = users.FOTOS_DIR / Path(url).name
            downloaded = client.get(url)
            assert downloaded.status_code == 200
            assert downloaded.content == picture
            db.expire(user)
            assert user.foto_url == url
        finally:
            client.close()
            if stored_path is not None:
                stored_path.unlink(missing_ok=True)  # Solo el fichero creado aquí.
    engine.dispose()
