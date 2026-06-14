from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import SecurityMode


class SystemSettingUpsert(BaseModel):
    value: dict = Field(..., min_length=1)
    description: str | None = None


class SecurityModeRead(BaseModel):
    mode: SecurityMode
    description: str


class SecurityModeUpdate(BaseModel):
    mode: SecurityMode


class AiAlertSettingsRead(BaseModel):
    enabled: bool = True
    timeout_seconds: float = Field(default=10, ge=1, le=30)
    max_words: int = Field(default=10, ge=4, le=20)
    no_face_prompt: str = Field(default="", max_length=500)
    unknown_face_prompt: str = Field(default="", max_length=500)
    known_person_prompt: str = Field(default="", max_length=500)


class AiAlertSettingsUpdate(BaseModel):
    enabled: bool = True
    timeout_seconds: float = Field(default=10, ge=1, le=30)
    max_words: int = Field(default=10, ge=4, le=20)
    no_face_prompt: str = Field(default="", max_length=500)
    unknown_face_prompt: str = Field(default="", max_length=500)
    known_person_prompt: str = Field(default="", max_length=500)


class DailyReportSettingsRead(BaseModel):
    report_email_to: str = Field(default="", max_length=255)
    report_time: str = Field(default="23:00", pattern=r"^\d{2}:\d{2}$")
    timezone: str = Field(default="Asia/Beirut", max_length=80)


class DailyReportSettingsUpdate(BaseModel):
    report_email_to: str = Field(default="", max_length=255)
    report_time: str = Field(default="23:00", pattern=r"^\d{2}:\d{2}$")
    timezone: str = Field(default="Asia/Beirut", max_length=80)


class SystemSettingRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    key: str
    value: dict
    description: str | None
    updated_at: datetime
