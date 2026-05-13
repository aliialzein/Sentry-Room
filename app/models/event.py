from __future__ import annotations

from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, Float, ForeignKey, Integer, JSON, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.enums import EventSeverity, EventType


class AccessEvent(Base):
    __tablename__ = "access_events"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    event_type: Mapped[EventType] = mapped_column(Enum(EventType, native_enum=False), index=True)
    severity: Mapped[EventSeverity] = mapped_column(
        Enum(EventSeverity, native_enum=False),
        default=EventSeverity.INFO,
        index=True,
    )
    message: Mapped[str] = mapped_column(Text)
    person_id: Mapped[int | None] = mapped_column(ForeignKey("persons.id", ondelete="SET NULL"), nullable=True)
    confidence: Mapped[float | None] = mapped_column(Float, nullable=True)
    snapshot_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
    sensor_payload: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    is_acknowledged: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), index=True)

    person: Mapped["Person | None"] = relationship("Person", back_populates="events")
    alerts: Mapped[list["AlertDelivery"]] = relationship(
        "AlertDelivery",
        back_populates="event",
        cascade="all, delete-orphan",
    )
