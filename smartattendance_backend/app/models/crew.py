# app/models/crew.py
"""
SQLAlchemy ORM models for Crews (Cuadrillas), Work Zones (Geocercas), and Positions.
"""
from datetime import datetime, timezone
from sqlalchemy import String, DateTime, Integer, Float, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base


class WorkZone(Base):
    __tablename__ = "work_zones"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    radius_m: Mapped[float] = mapped_column(Float, nullable=False, default=100.0)
    address: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    crews: Mapped[list["Crew"]] = relationship(back_populates="zone")


class Crew(Base):
    __tablename__ = "crews"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    supervisor_document: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    driver_document: Mapped[str | None] = mapped_column(String(50), nullable=True)
    zone_id: Mapped[int | None] = mapped_column(ForeignKey("work_zones.id"), nullable=True)
    valid_from: Mapped[str] = mapped_column(String(50), nullable=False)
    valid_until: Mapped[str] = mapped_column(String(50), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    zone: Mapped[WorkZone | None] = relationship(back_populates="crews")
    positions: Mapped[list["CrewPosition"]] = relationship(back_populates="crew", cascade="all, delete-orphan")


class CrewPosition(Base):
    __tablename__ = "crew_positions"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    crew_id: Mapped[int] = mapped_column(ForeignKey("crews.id"), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(100), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    crew: Mapped[Crew] = relationship(back_populates="positions")
