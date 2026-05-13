from __future__ import annotations

from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, JSON, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Person(Base):
    __tablename__ = "persons"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    full_name: Mapped[str] = mapped_column(String(120), nullable=False, index=True)
    role: Mapped[str | None] = mapped_column(String(80), nullable=True)
    is_authorized: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    face_encoding: Mapped[list[float] | None] = mapped_column(JSON, nullable=True)
    image_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )

    events: Mapped[list["AccessEvent"]] = relationship("AccessEvent", back_populates="person")
