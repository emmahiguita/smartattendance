"""Validation contracts for internal messaging."""
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


class MessageCreate(BaseModel):
    recipient_id: int = Field(gt=0)
    body: str = Field(min_length=1, max_length=2000)

    @field_validator("body")
    @classmethod
    def normalize_body(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("El mensaje no puede estar vacío.")
        return value


class MessageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    sender_id: int
    recipient_id: int
    body: str
    read_at: datetime | None
    created_at: datetime
    sender_name: str
    recipient_name: str


class MessageContact(BaseModel):
    id: int
    nombre: str
    apellido: str
    cargo: str
    foto_url: str | None = None
    unread_count: int = 0
    last_message: str | None = None
    last_message_at: datetime | None = None
