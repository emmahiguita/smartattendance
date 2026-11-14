"""El límite de fotos también debe limitar la memoria de lectura."""
from tempfile import TemporaryFile
import pytest
from fastapi import HTTPException, UploadFile
from starlette.datastructures import Headers
from app.api.v1.endpoints.users import upload_foto


@pytest.mark.asyncio
async def test_oversized_photo_is_rejected_without_reading_entire_file():
    limit = 2 * 1024 * 1024
    with TemporaryFile() as stream:
        stream.write(b'\xff\xd8\xff' + b'x' * (3 * 1024 * 1024))
        stream.seek(0)
        upload = UploadFile(file=stream, filename='large.jpg',
                            headers=Headers({'content-type': 'image/jpeg'}))
        with pytest.raises(HTTPException) as error:
            await upload_foto(file=upload, db=None, current_user=None)
        assert error.value.status_code == 400
        assert stream.tell() <= limit + 1
