from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import EventSeverity, EventType


class EventCreate(BaseModel):
    event_type: EventType
    message: str = Field(..., min_length=1)
    severity: EventSeverity = EventSeverity.INFO
    person_id: int | None = None
    confidence: float | None = Field(default=None, ge=0, le=1)
    snapshot_path: str | None = None
    snapshot_base64: str | None = None
    sensor_payload: dict | None = None


class DetectionRequest(BaseModel):
    image_base64: str = Field(..., min_length=1)
    sensor_payload: dict | None = None


class EventRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    event_type: EventType
    severity: EventSeverity
    message: str
    person_id: int | None
    confidence: float | None
    snapshot_path: str | None
    sensor_payload: dict | None
    is_acknowledged: bool
    created_at: datetime
