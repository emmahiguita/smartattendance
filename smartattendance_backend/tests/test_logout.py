"""Revocación de una sesión por HTTP, con rotación y SQLite real temporal."""
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from app.core.hashing import hash_password
from app.database.base import Base, get_db
from app.models.user import User
from app.services.session_service import issue
from main import create_app


def test_logout_revokes_rotated_session_but_preserves_another(tmp_path):
    engine = create_engine('sqlite:///' + str(tmp_path / 'logout.db'))
    Base.metadata.create_all(engine)
    with Session(engine) as db:
        user = User(nombre='QA', apellido='Salida', cedula='99112233',
                    correo='qa-logout@example.com', cargo='Empleado',
                    hashed_password=hash_password('PruebaSegura9'))
        db.add(user)
        db.commit()
        old_access, old_refresh = issue(db, user)
        other_access, _ = issue(db, user)

    def temp_database():
        with Session(engine) as db:
            yield db

    app = create_app()
    app.dependency_overrides[get_db] = temp_database
    client = TestClient(app, client=('127.0.0.77', 50000))
    url = '/api/v1/auth'
    try:
        rotated = client.post(f'{url}/refresh', json={'refresh_token': old_refresh})
        assert rotated.status_code == 200
        new_tokens = rotated.json()
        for _ in range(2):
            response = client.post(f'{url}/logout', json={'refresh_token': old_refresh})
            assert response.status_code == 204
        for access in (old_access, new_tokens['access_token']):
            assert client.get('/api/v1/users/me', headers={'Authorization': f'Bearer {access}'}).status_code == 401
        assert client.post(f'{url}/refresh', json={'refresh_token': new_tokens['refresh_token']}).status_code == 401
        assert client.get('/api/v1/users/me', headers={'Authorization': f'Bearer {other_access}'}).status_code == 200
    finally:
        client.close()
        engine.dispose()
