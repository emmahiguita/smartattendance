"""Las pruebas firman con una clave efímera, nunca con la clave real del entorno."""
import secrets
import os
import pytest
# Solo este proceso de pruebas; permite CI sin cargar un secreto real del .env.
os.environ['SECRET_KEY'] = secrets.token_urlsafe(48)
from app.core.config import settings


@pytest.fixture(scope='session', autouse=True)
def isolated_signing_key():
    original = settings.SECRET_KEY
    settings.SECRET_KEY = secrets.token_urlsafe(48)
    try:
        yield
    finally:
        settings.SECRET_KEY = original
