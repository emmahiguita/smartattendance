# app/schemas/crew.py
"""
Pydantic schemas for Crews and Work Zones.
"""
from datetime import datetime
from pydantic import BaseModel, Field


class WorkZoneBase(BaseModel):
    name: str = Field(..., max_length=100)
    latitude: float
    longitude: float
    radius_m: float = 100.0
    address: str | None = None


class WorkZoneCreate(WorkZoneBase):
    pass


class WorkZoneResponse(WorkZoneBase):
    model_config = {"from_attributes": True}

    id: int
    created_at: datetime


class CrewPositionBase(BaseModel):
    title: str = Field(..., max_length=100)


class CrewPositionResponse(CrewPositionBase):
    model_config = {"from_attributes": True}

    id: int
    crew_id: int
    created_at: datetime


class CrewBase(BaseModel):
    name: str = Field(..., max_length=100)
    supervisor_document: str = Field(..., max_length=50)
    driver_document: str | None = None
    zone_id: int | None = None
    valid_from: str
    valid_until: str


class CrewCreate(CrewBase):
    positions: list[str] = Field(default_factory=list)


class CrewResponse(CrewBase):
    model_config = {"from_attributes": True}

    id: int
    created_at: datetime
    positions: list[CrewPositionResponse] = Field(default_factory=list)
