from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import EmergencyIncidentStatus


class EmergencyIncidentCreate(BaseModel):
    emergency_type: str = Field(..., min_length=1, max_length=80)
    emergency_title: str = Field(..., min_length=1, max_length=120)
    action_type: str = Field(..., min_length=1, max_length=80)
    contact_name: str = Field(..., min_length=1, max_length=120)
    contact_phone: str | None = Field(default=None, max_length=50)
    contact_email: str | None = Field(default=None, max_length=120)
    manual_location: str = Field(..., min_length=1, max_length=250)
    gps_latitude: float | None = None
    gps_longitude: float | None = None
    status: EmergencyIncidentStatus = EmergencyIncidentStatus.CONFIRMED
    source: str = Field(default="mobile_app", max_length=80)
    details: dict[str, Any] | None = None
    recorded_at: datetime | None = None


class EmergencyIncidentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    emergency_type: str
    emergency_title: str
    action_type: str
    contact_name: str
    contact_phone: str | None
    contact_email: str | None
    manual_location: str
    gps_latitude: float | None
    gps_longitude: float | None
    status: EmergencyIncidentStatus
    source: str
    details: dict[str, Any] | None
    reported_by_user_id: int | None
    recorded_at: datetime
    created_at: datetime
    updated_at: datetime
