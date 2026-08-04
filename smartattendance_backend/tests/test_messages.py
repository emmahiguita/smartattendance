from fastapi.testclient import TestClient
import pytest

from app.core.security import create_access_token
from app.database.base import Base, SessionLocal, engine
from app.models.message import Message
from app.models.user import User
from main import app


@pytest.fixture(autouse=True)
def messaging_data():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    db.query(Message).delete()
    for user_id, cedula, correo, nombre in (
        (101, "msg101", "msg101@test.com", "Ana"),
        (102, "msg102", "msg102@test.com", "Luis"),
        (103, "msg103", "msg103@test.com", "Marta"),
    ):
        user = db.get(User, user_id)
        if user is None:
            db.add(User(
                id=user_id, nombre=nombre, apellido="Mensajería", cedula=cedula,
                correo=correo, cargo="Empleado", is_active=True,
            ))
    db.commit()
    db.close()
    yield
    db = SessionLocal()
    db.query(Message).delete()
    db.query(User).filter(User.id.in_([101, 102, 103])).delete(synchronize_session=False)
    db.commit()
    db.close()


def auth(user_id: int) -> dict[str, str]:
    return {"Authorization": f"Bearer {create_access_token(data={'sub': str(user_id)})}"}


def test_contacts_are_available_to_all_employees():
    response = TestClient(app).get("/api/v1/messages/contacts", headers=auth(101))
    assert response.status_code == 200
    ids = {item["id"] for item in response.json()}
    assert {102, 103}.issubset(ids)
    assert 101 not in ids


def test_send_list_read_and_unread_flow():
    client = TestClient(app)
    sent = client.post(
        "/api/v1/messages/",
        json={"recipient_id": 102, "body": "  Reunión a las 3 PM  "},
        headers=auth(101),
    )
    assert sent.status_code == 201
    payload = sent.json()
    assert payload["body"] == "Reunión a las 3 PM"
    message_id = payload["id"]

    conversation = client.get(
        "/api/v1/messages/?with_user_id=101", headers=auth(102)
    )
    assert conversation.status_code == 200
    assert [item["id"] for item in conversation.json()] == [message_id]

    unread = client.get("/api/v1/messages/unread/count", headers=auth(102))
    assert unread.json() == {"count": 1}

    read = client.patch(f"/api/v1/messages/{message_id}/read", headers=auth(102))
    assert read.status_code == 200
    assert read.json()["read_at"] is not None
    assert client.get("/api/v1/messages/unread/count", headers=auth(102)).json() == {"count": 0}


def test_messages_are_private_and_input_is_validated():
    client = TestClient(app)
    sent = client.post(
        "/api/v1/messages/",
        json={"recipient_id": 102, "body": "Privado"},
        headers=auth(101),
    )
    message_id = sent.json()["id"]

    third_party = client.get(
        "/api/v1/messages/?with_user_id=101", headers=auth(103)
    )
    assert third_party.json() == []
    assert client.patch(
        f"/api/v1/messages/{message_id}/read", headers=auth(103)
    ).status_code == 404
    assert client.post(
        "/api/v1/messages/",
        json={"recipient_id": 102, "body": "   "},
        headers=auth(101),
    ).status_code == 422


def test_contacts_sort_mixed_conversations_without_timezone_error():
    client = TestClient(app)
    sent = client.post(
        "/api/v1/messages/",
        json={"recipient_id": 102, "body": "Mensaje reciente"},
        headers=auth(101),
    )
    assert sent.status_code == 201
    response = client.get("/api/v1/messages/contacts", headers=auth(101))
    assert response.status_code == 200
    contacts = response.json()
    assert contacts[0]["id"] == 102
    assert any(item["id"] == 103 and item["last_message_at"] is None for item in contacts)


def test_mark_conversation_read_updates_only_selected_sender():
    client = TestClient(app)
    for sender in (101, 103):
        response = client.post(
            "/api/v1/messages/",
            json={"recipient_id": 102, "body": f"Mensaje de {sender}"},
            headers=auth(sender),
        )
        assert response.status_code == 201

    read = client.patch("/api/v1/messages/read-all/101", headers=auth(102))
    assert read.status_code == 200
    assert read.json() == {"updated": 1}
    assert client.get("/api/v1/messages/unread/count", headers=auth(102)).json() == {"count": 1}
