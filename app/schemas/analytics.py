from datetime import date
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field


class AnalyticsRange(str, Enum):
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"


class AnalyticsSummary(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    total_incidents: int = Field(alias="totalIncidents")
    pending_sync: int = Field(alias="pendingSync")
    successful_actions: int = Field(alias="successfulActions")
    failed_actions: int = Field(alias="failedActions")
    most_common_type: str | None = Field(alias="mostCommonType")


class AnalyticsTypeCount(BaseModel):
    type: str
    count: int


class AnalyticsActionCount(BaseModel):
    action: str
    count: int


class AnalyticsTrendPoint(BaseModel):
    date: date
    count: int
