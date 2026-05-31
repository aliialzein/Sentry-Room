from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.analytics import AnalyticsRange

AIReportRange = AnalyticsRange


class AIReportResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    report_range: str = Field(alias="range")
    generated_at: datetime = Field(alias="generatedAt")
    summary: str
    key_findings: list[str] = Field(alias="keyFindings")
    recommendations: list[str]


class AIAnalyticsPayload(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    total_incidents: int = Field(alias="totalIncidents")
    pending_sync: int = Field(alias="pendingSync")
    successful_actions: int = Field(alias="successfulActions")
    failed_actions: int = Field(alias="failedActions")
    most_common_type: str | None = Field(alias="mostCommonType")
    incident_types: dict[str, int] = Field(alias="incidentTypes")
    actions: dict[str, int]
    trends: list[dict[str, Any]]
