from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import SensorType


class SensorReadingCreate(BaseModel):
    sensor_type: SensorType
    value: dict = Field(..., min_length=1)
    unit: str | None = Field(default=None, max_length=40)
    source: str | None = Field(default=None, max_length=80)


class SensorReadingRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    sensor_type: SensorType
    value: dict
    unit: str | None
    source: str | None
    created_at: datetime
