from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class SystemSettingUpsert(BaseModel):
    value: dict = Field(..., min_length=1)
    description: str | None = None


class SystemSettingRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    key: str
    value: dict
    description: str | None
    updated_at: datetime
