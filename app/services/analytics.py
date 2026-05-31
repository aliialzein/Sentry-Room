from datetime import date, datetime, time, timedelta, timezone

from sqlalchemy.orm import Session

from app.repositories.analytics import AnalyticsRepository
from app.schemas.analytics import (
    AnalyticsActionCount,
    AnalyticsRange,
    AnalyticsSummary,
    AnalyticsTrendPoint,
    AnalyticsTypeCount,
)


class AnalyticsService:
    _type_labels = {
        "fire": "Fire Emergency",
        "security": "Security Threat",
        "humidity": "High Humidity / Fan Issue",
        "medical": "Medical Emergency",
        "support": "General Support",
    }

    _action_labels = {
        "call": "Call",
        "sms": "SMS",
        "email": "Email",
        "shareLocation": "Share",
        "share_location": "Share",
        "share": "Share",
    }

    def __init__(self, repository: AnalyticsRepository | None = None) -> None:
        self._repository = repository or AnalyticsRepository()

    def get_summary(self, db: Session, analytics_range: AnalyticsRange) -> AnalyticsSummary:
        start_at = self.range_start_at(analytics_range)
        total, pending, successful, failed = self._repository.get_summary_counts(db, start_at)
        most_common_type = self._repository.get_most_common_type(db, start_at)

        return AnalyticsSummary(
            totalIncidents=total,
            pendingSync=pending,
            successfulActions=successful,
            failedActions=failed,
            mostCommonType=self.format_emergency_type(most_common_type) if most_common_type else None,
        )

    def get_counts_by_type(self, db: Session, analytics_range: AnalyticsRange) -> list[AnalyticsTypeCount]:
        start_at = self.range_start_at(analytics_range)
        rows = self._repository.get_counts_by_type(db, start_at)
        return [
            AnalyticsTypeCount(type=self.format_emergency_type(emergency_type), count=count)
            for emergency_type, count in rows
        ]

    def get_counts_by_action(self, db: Session, analytics_range: AnalyticsRange) -> list[AnalyticsActionCount]:
        start_at = self.range_start_at(analytics_range)
        rows = self._repository.get_counts_by_action(db, start_at)
        return [
            AnalyticsActionCount(action=self.format_action_type(action_type), count=count)
            for action_type, count in rows
        ]

    def get_trends(self, db: Session, analytics_range: AnalyticsRange) -> list[AnalyticsTrendPoint]:
        start_at = self.range_start_at(analytics_range)
        rows = self._repository.get_trends(db, start_at)
        counts_by_day = {self._coerce_date(raw_date): count for raw_date, count in rows}

        if not counts_by_day:
            return []

        start_date = start_at.date()
        today = datetime.now(timezone.utc).date()
        days = (today - start_date).days
        return [
            AnalyticsTrendPoint(date=start_date + timedelta(days=offset), count=counts_by_day.get(start_date + timedelta(days=offset), 0))
            for offset in range(days + 1)
        ]

    def range_start_at(self, analytics_range: AnalyticsRange) -> datetime:
        today = datetime.now(timezone.utc).date()
        if analytics_range == AnalyticsRange.DAILY:
            start_date = today
        elif analytics_range == AnalyticsRange.WEEKLY:
            start_date = today - timedelta(days=6)
        else:
            start_date = today - timedelta(days=29)

        return datetime.combine(start_date, time.min, tzinfo=timezone.utc)

    def range_label(self, analytics_range: AnalyticsRange) -> str:
        if analytics_range == AnalyticsRange.DAILY:
            return "Daily"
        if analytics_range == AnalyticsRange.WEEKLY:
            return "Weekly"
        return "Monthly"

    def format_emergency_type(self, emergency_type: str) -> str:
        if emergency_type in self._type_labels:
            return self._type_labels[emergency_type]
        return self._humanize(emergency_type)

    def format_action_type(self, action_type: str) -> str:
        if action_type in self._action_labels:
            return self._action_labels[action_type]
        return self._humanize(action_type)

    def _humanize(self, value: str) -> str:
        words = value.replace("_", " ").replace("-", " ").split()
        if not words:
            return "Unknown"
        return " ".join(word[:1].upper() + word[1:] for word in words)

    def _coerce_date(self, value: object) -> date:
        if isinstance(value, date):
            return value
        return date.fromisoformat(str(value))
