"""Recuperación con base SQLite real y sesiones independientes."""
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from fastapi import HTTPException
import app.models
from app.database.base import Base
from app.models.auth_state import PasswordChallenge
from app.services.challenge_store import issue, consume
import time


def test_code_persists_is_hashed_and_can_only_be_consumed_once(tmp_path):
    engine = create_engine('sqlite:///'+str(tmp_path/'codes.db'))
    Base.metadata.create_all(engine)
    with Session(engine) as db:
        code, _ = issue(db, '99881122', 'qa@example.com')
        assert db.query(PasswordChallenge).one().digest != code
    with Session(engine) as db:
        consume(db, '99881122', 'qa@example.com', code)
        db.commit()
    with Session(engine) as db:
        with pytest.raises(HTTPException):
            consume(db, '99881122', 'qa@example.com', code)
    engine.dispose()


def test_expiry_and_replacement_generation(tmp_path):
    engine = create_engine('sqlite:///'+str(tmp_path/'expiry.db'))
    Base.metadata.create_all(engine)
    with Session(engine) as db:
        first, generation = issue(db, '99881122', 'qa@example.com')
        second, replacement = issue(db, '99881122', 'qa@example.com')
        assert replacement != generation
        challenge = db.query(PasswordChallenge).one()
        challenge.expires_at = time.time()-1
        db.commit()
        with pytest.raises(HTTPException):
            consume(db, '99881122', 'qa@example.com', second)
        db.rollback()
    engine.dispose()


def test_five_wrong_attempts_block_the_correct_code_across_sessions(tmp_path):
    engine = create_engine('sqlite:///'+str(tmp_path/'attempts.db'))
    Base.metadata.create_all(engine)
    with Session(engine) as db:
        code, _ = issue(db, '99881122', 'qa@example.com')
    for _ in range(5):
        with Session(engine) as db, pytest.raises(HTTPException):
            consume(db, '99881122', 'qa@example.com', 'incorrecto')
    with Session(engine) as db, pytest.raises(HTTPException):
        consume(db, '99881122', 'qa@example.com', code)
    engine.dispose()
