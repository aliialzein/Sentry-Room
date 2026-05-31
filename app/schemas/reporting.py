from datetime import datetime

from pydantic import BaseModel

from app.schemas.ai_reporting import AIReportResponse
from app.schemas.analytics import (
    AnalyticsActionCount,
    AnalyticsRange,
    AnalyticsSummary,
    AnalyticsTrendPoint,
    AnalyticsTypeCount,
)

ReportRange = AnalyticsRange


class ReportIncidentSummary(BaseModel):
    recorded_at: datetime
    emergency_type: str
    action_type: str
    location: str
    status: str


class AnalyticsPdfReportData(BaseModel):
    generated_at: datetime
    range_label: str
    summary: AnalyticsSummary
    type_breakdown: list[AnalyticsTypeCount]
    action_breakdown: list[AnalyticsActionCount]
    trends: list[AnalyticsTrendPoint]
    recent_incidents: list[ReportIncidentSummary]
    ai_summary: AIReportResponse | None = None
