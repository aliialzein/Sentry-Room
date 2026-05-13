from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class PersonCreate(BaseModel):
    full_name: str = Field(..., min_length=1, max_length=120)
    role: str | None = Field(default=None, max_length=80)
    is_authorized: bool = True
    face_encoding: list[float] | None = None
    image_path: str | None = None
    notes: str | None = None


class PersonUpdate(BaseModel):
    full_name: str | None = Field(default=None, min_length=1, max_length=120)
    role: str | None = Field(default=None, max_length=80)
    is_authorized: bool | None = None
    face_encoding: list[float] | None = None
    image_path: str | None = None
    notes: str | None = None


class EnrollImageRequest(BaseModel):
    full_name: str = Field(..., min_length=1, max_length=120)
    image_base64: str = Field(..., min_length=1)
    role: str | None = Field(default=None, max_length=80)
    is_authorized: bool = True
    notes: str | None = None


class PersonRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    role: str | None
    is_authorized: bool
    image_path: str | None
    notes: str | None
    created_at: datetime
    updated_at: datetime
