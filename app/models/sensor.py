from datetime import datetime

from sqlalchemy import DateTime, Enum, Integer, JSON, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.enums import SensorType


class SensorReading(Base):
    __tablename__ = "sensor_readings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    sensor_type: Mapped[SensorType] = mapped_column(Enum(SensorType, native_enum=False), index=True)
    value: Mapped[dict] = mapped_column(JSON)
    unit: Mapped[str | None] = mapped_column(String(40), nullable=True)
    source: Mapped[str | None] = mapped_column(String(80), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), index=True)
