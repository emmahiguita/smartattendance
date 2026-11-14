"""Bloqueo local del motor: el sistema libera la exclusión si el proceso termina."""
import os
import re
from pathlib import Path


def acquire(serial):
    directory = Path(os.getenv('LOCALAPPDATA', str(Path.home()))) / 'SmartAttendanceQA'
    directory.mkdir(exist_ok=True)
    path = directory / ('device_'+re.sub(r'[^\w.-]', '_', serial)+'.lock')
    stream = path.open('a+b')
    stream.seek(0, 2)
    if stream.tell() == 0:
        stream.write(b'0')
        stream.flush()
    stream.seek(0)
    try:
        if os.name == 'nt':
            import msvcrt
            msvcrt.locking(stream.fileno(), msvcrt.LK_NBLCK, 1)
        else:
            import fcntl
            fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError as error:
        stream.close()
        raise RuntimeError('Otra ejecución del motor está usando este Android.') from error
    return stream
