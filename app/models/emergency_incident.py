from datetime import datetime

from sqlalchemy import DateTime, Enum, Float, ForeignKey, Integer, JSON, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.enums import EmergencyIncidentStatus


class EmergencyIncident(Base):
    __tablename__ = "emergency_incidents"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    emergency_type: Mapped[str] = mapped_column(String(80), nullable=False, index=True)
    emergency_title: Mapped[str] = mapped_column(String(120), nullable=False)
    action_type: Mapped[str] = mapped_column(String(80), nullable=False)
    contact_name: Mapped[str] = mapped_column(String(120), nullable=False)
    contact_phone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    contact_email: Mapped[str | None] = mapped_column(String(120), nullable=True)
    manual_location: Mapped[str] = mapped_column(String(250), nullable=False)
    gps_latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    gps_longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    status: Mapped[EmergencyIncidentStatus] = mapped_column(
        Enum(EmergencyIncidentStatus, native_enum=False),
        default=EmergencyIncidentStatus.CONFIRMED,
        nullable=False,
        index=True,
    )
    source: Mapped[str] = mapped_column(String(80), default="mobile_app", nullable=False, index=True)
    details: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    reported_by_user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), index=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )

    reported_by_user: Mapped["User | None"] = relationship("User")
