import json
import unittest
from datetime import date

from app.core.config import Settings
from app.schemas.analytics import (
    AnalyticsActionCount,
    AnalyticsRange,
    AnalyticsSummary,
    AnalyticsTrendPoint,
    AnalyticsTypeCount,
)
from app.services.ai_reporting import AIReportingService


class _FakeAnalyticsService:
    def get_summary(self, db, analytics_range):
        return AnalyticsSummary(
            totalIncidents=42,
            pendingSync=3,
            successfulActions=38,
            failedActions=4,
            mostCommonType="Security Threat",
        )

    def get_counts_by_type(self, db, analytics_range):
        return [
            AnalyticsTypeCount(type="Security Threat", count=18),
            AnalyticsTypeCount(type="Fire Emergency", count=7),
        ]

    def get_counts_by_action(self, db, analytics_range):
        return [
            AnalyticsActionCount(action="Call", count=20),
            AnalyticsActionCount(action="SMS", count=10),
        ]

    def get_trends(self, db, analytics_range):
        return [
            AnalyticsTrendPoint(date=date(2026, 5, 30), count=2),
            AnalyticsTrendPoint(date=date(2026, 5, 31), count=5),
        ]


class _FailingClient:
    class responses:
        @staticmethod
        def create(**kwargs):
            raise TimeoutError("timeout")


class AIReportingServiceTests(unittest.TestCase):
    def setUp(self):
        AIReportingService._cache.clear()
        AIReportingService._request_log.clear()

    def _service(self, api_key=None, client=None):
        return AIReportingService(
            analytics_service=_FakeAnalyticsService(),
            settings=Settings(openai_api_key=api_key, openai_model="gpt-test"),
            client=client,
        )

    def test_build_analytics_payload_uses_aggregated_data_only(self):
        payload = self._service().build_analytics_payload(
            db=None,
            report_range=AnalyticsRange.DAILY,
        )
        data = payload.model_dump(by_alias=True)

        self.assertEqual(data["totalIncidents"], 42)
        self.assertEqual(data["incidentTypes"]["Security Threat"], 18)
        self.assertEqual(data["actions"]["Call"], 20)
        self.assertNotIn("contactName", json.dumps(data))
        self.assertNotIn("contactPhone", json.dumps(data))
        self.assertNotIn("gpsLatitude", json.dumps(data))
        self.assertNotIn("location", json.dumps(data).lower())

    def test_prompt_generation_includes_rules_and_payload(self):
        service = self._service()
        payload = service.build_analytics_payload(db=None, report_range=AnalyticsRange.WEEKLY)
        prompt = service.build_prompt(payload)

        self.assertIn("Do not calculate new counts", prompt)
        self.assertIn('"totalIncidents":42', prompt)
        self.assertIn('"Security Threat":18', prompt)
        self.assertNotIn("Contact", prompt)
        self.assertNotIn("GPS", prompt)

    def test_ai_response_parsing(self):
        result = self._service().parse_ai_response(
            json.dumps(
                {
                    "summary": "Security incidents dominated the reporting period.",
                    "keyFindings": ["Security Threat was the dominant type."],
                    "recommendations": ["Review escalation coverage."],
                }
            ),
            report_range=AnalyticsRange.MONTHLY,
        )

        self.assertEqual(result.report_range, "monthly")
        self.assertIn("Security incidents", result.summary)
        self.assertEqual(result.key_findings, ["Security Threat was the dominant type."])
        self.assertEqual(result.recommendations, ["Review escalation coverage."])

    def test_missing_api_key_returns_safe_fallback(self):
        result = self._service(api_key=None).generate_summary(
            db=None,
            report_range=AnalyticsRange.DAILY,
            user_id=1,
        )

        self.assertEqual(result.summary, "AI summary unavailable.")
        self.assertEqual(result.key_findings, [])
        self.assertEqual(result.recommendations, [])

    def test_openai_failure_returns_safe_fallback(self):
        result = self._service(api_key="test-key", client=_FailingClient()).generate_summary(
            db=None,
            report_range=AnalyticsRange.DAILY,
            user_id=1,
        )

        self.assertEqual(result.summary, "AI summary unavailable.")


if __name__ == "__main__":
    unittest.main()
