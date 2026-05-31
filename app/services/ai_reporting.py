from __future__ import annotations

import hashlib
import json
import time
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any

from openai import APIConnectionError, APIStatusError, APITimeoutError, OpenAI
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.schemas.ai_reporting import AIAnalyticsPayload, AIReportResponse
from app.schemas.analytics import AnalyticsActionCount, AnalyticsRange, AnalyticsTypeCount
from app.services.analytics import AnalyticsService


SYSTEM_PROMPT = """You are a safety operations analyst.

Generate:
1. Executive Summary
2. Key Findings
3. Recommendations

Rules:
* Professional tone
* 150-300 words
* No fabricated numbers
* Only use supplied data
* Mention trends if supported
* Mention dominant incident types
* Mention operational concerns
* No markdown formatting"""


class AIRateLimitExceeded(Exception):
    pass


@dataclass
class _CacheEntry:
    response: AIReportResponse
    expires_at: datetime


class AIReportingService:
    _cache: dict[str, _CacheEntry] = {}
    _request_log: dict[int, list[float]] = {}
    _cache_ttl = timedelta(hours=24)
    _rate_limit_window_seconds = 60 * 60
    _max_requests_per_window = 10

    def __init__(
        self,
        analytics_service: AnalyticsService | None = None,
        settings: Settings | None = None,
        client: Any | None = None,
    ) -> None:
        self._analytics_service = analytics_service or AnalyticsService()
        self._settings = settings or get_settings()
        self._client = client

    def generate_summary(
        self,
        db: Session,
        report_range: AnalyticsRange,
        user_id: int,
    ) -> AIReportResponse:
        self._enforce_rate_limit(user_id)
        payload = self.build_analytics_payload(db=db, report_range=report_range)
        cache_key = self._cache_key(report_range, payload)
        cached = self._cache.get(cache_key)
        now = datetime.now(timezone.utc)

        if cached and cached.expires_at > now:
            return cached.response

        if not self._settings.openai_api_key:
            return self._fallback_response(
                report_range=report_range,
                reason="AI summary unavailable.",
            )

        try:
            content = self._request_openai_summary(payload)
            response = self.parse_ai_response(content, report_range=report_range)
        except (APIConnectionError, APIStatusError, APITimeoutError, TimeoutError, ValueError, json.JSONDecodeError):
            return self._fallback_response(
                report_range=report_range,
                reason="AI summary unavailable.",
            )

        self._cache[cache_key] = _CacheEntry(
            response=response,
            expires_at=now + self._cache_ttl,
        )
        return response

    def build_analytics_payload(self, db: Session, report_range: AnalyticsRange) -> AIAnalyticsPayload:
        summary = self._analytics_service.get_summary(db=db, analytics_range=report_range)
        type_breakdown = self._analytics_service.get_counts_by_type(db=db, analytics_range=report_range)
        action_breakdown = self._analytics_service.get_counts_by_action(db=db, analytics_range=report_range)
        trends = self._analytics_service.get_trends(db=db, analytics_range=report_range)

        return AIAnalyticsPayload(
            totalIncidents=summary.total_incidents,
            pendingSync=summary.pending_sync,
            successfulActions=summary.successful_actions,
            failedActions=summary.failed_actions,
            mostCommonType=summary.most_common_type,
            incidentTypes=self._count_map(type_breakdown),
            actions=self._count_map(action_breakdown),
            trends=[
                {
                    "date": trend.date.isoformat(),
                    "count": trend.count,
                }
                for trend in trends
            ],
        )

    def build_prompt(self, payload: AIAnalyticsPayload) -> str:
        compact_payload = payload.model_dump(by_alias=True)
        return (
            "Generate a management-ready emergency analytics summary from the aggregated statistics below. "
            "Do not calculate new counts. Do not infer from any data not supplied. "
            "Return JSON with keys summary, keyFindings, and recommendations.\n\n"
            f"Aggregated analytics payload:\n{json.dumps(compact_payload, sort_keys=True, separators=(',', ':'))}"
        )

    def parse_ai_response(self, content: str, report_range: AnalyticsRange) -> AIReportResponse:
        decoded = json.loads(content)
        if not isinstance(decoded, dict):
            raise ValueError("AI response must be a JSON object.")

        summary = str(decoded.get("summary") or "").strip()
        key_findings = self._string_list(decoded.get("keyFindings") or decoded.get("key_findings"))
        recommendations = self._string_list(decoded.get("recommendations"))

        if not summary:
            raise ValueError("AI response is missing a summary.")

        return AIReportResponse(
            range=report_range.value,
            generatedAt=datetime.now(timezone.utc),
            summary=summary,
            keyFindings=key_findings[:6],
            recommendations=recommendations[:6],
        )

    def safe_generate_summary(
        self,
        db: Session,
        report_range: AnalyticsRange,
        user_id: int,
    ) -> AIReportResponse:
        try:
            return self.generate_summary(db=db, report_range=report_range, user_id=user_id)
        except AIRateLimitExceeded:
            return self._fallback_response(report_range=report_range, reason="AI summary unavailable.")
        except Exception:
            return self._fallback_response(report_range=report_range, reason="AI summary unavailable.")

    def _request_openai_summary(self, payload: AIAnalyticsPayload) -> str:
        client = self._client or OpenAI(api_key=self._settings.openai_api_key, timeout=20)
        response = client.responses.create(
            model=self._settings.openai_model,
            instructions=SYSTEM_PROMPT,
            input=self.build_prompt(payload),
            text={
                "format": {
                    "type": "json_schema",
                    "name": "sentry_room_ai_summary",
                    "strict": True,
                    "schema": {
                        "type": "object",
                        "additionalProperties": False,
                        "properties": {
                            "summary": {"type": "string"},
                            "keyFindings": {
                                "type": "array",
                                "items": {"type": "string"},
                            },
                            "recommendations": {
                                "type": "array",
                                "items": {"type": "string"},
                            },
                        },
                        "required": ["summary", "keyFindings", "recommendations"],
                    },
                }
            },
        )
        output_text = getattr(response, "output_text", None)
        if not output_text:
            raise ValueError("AI response did not include output text.")
        return output_text

    def _fallback_response(self, report_range: AnalyticsRange, reason: str) -> AIReportResponse:
        return AIReportResponse(
            range=report_range.value,
            generatedAt=datetime.now(timezone.utc),
            summary=reason,
            keyFindings=[],
            recommendations=[],
        )

    def _enforce_rate_limit(self, user_id: int) -> None:
        now = time.time()
        cutoff = now - self._rate_limit_window_seconds
        entries = [timestamp for timestamp in self._request_log.get(user_id, []) if timestamp >= cutoff]
        if len(entries) >= self._max_requests_per_window:
            self._request_log[user_id] = entries
            raise AIRateLimitExceeded("AI summary request limit exceeded.")
        entries.append(now)
        self._request_log[user_id] = entries

    def _cache_key(self, report_range: AnalyticsRange, payload: AIAnalyticsPayload) -> str:
        snapshot = json.dumps(payload.model_dump(by_alias=True), sort_keys=True, default=str)
        digest = hashlib.sha256(snapshot.encode("utf-8")).hexdigest()
        return f"{report_range.value}:{digest}"

    def _count_map(self, items: list[AnalyticsTypeCount] | list[AnalyticsActionCount]) -> dict[str, int]:
        result: dict[str, int] = {}
        for item in items:
            label = item.type if isinstance(item, AnalyticsTypeCount) else item.action
            result[label] = item.count
        return result

    def _string_list(self, value: Any) -> list[str]:
        if not isinstance(value, list):
            return []
        return [str(item).strip() for item in value if str(item).strip()]
