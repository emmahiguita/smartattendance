"""La aplicación debe rechazar secretos ausentes, cortos o públicos."""
import pytest
from pydantic import ValidationError
from app.core.config import Settings


@pytest.mark.parametrize('key', [
    'short',
    'smartattendance-jwt-secret-change-in-production',
    ' smartattendance-jwt-secret-change-in-production ',
    'CAMBIAR_POR_SECRETO_ALEATORIO_DE_64_CHARS',
    ' CAMBIAR_POR_SECRETO_ALEATORIO_DE_64_CHARS ',
])
def test_unsafe_signing_secret_is_rejected(key):
    with pytest.raises(ValidationError):
        Settings(_env_file=None, SECRET_KEY=key)


def test_explicit_strong_secret_is_accepted():
    settings = Settings(_env_file=None, SECRET_KEY='Test-only-key-that-is-long-enough-123456789')
    assert len(settings.SECRET_KEY) >= 32


def test_example_sheet_setting_is_supported(tmp_path):
    config = tmp_path/'runtime.env'
    config.write_text('GOOGLE_SHEET_NAME=Hoja_QA\n', encoding='utf-8')
    settings = Settings(_env_file=config, SECRET_KEY='Test-only-key-that-is-long-enough-123456789')
    assert settings.GOOGLE_SHEET_NAME == 'Hoja_QA'
