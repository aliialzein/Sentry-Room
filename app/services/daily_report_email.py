from __future__ import annotations

import json
import smtplib
import ssl
import urllib.error
import urllib.request
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta, timezone
from email.message import EmailMessage
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models.enums import EventSeverity, EventType
from app.models.event import AccessEvent
from app.models.system import SystemSetting


DAILY_REPORT_SETTINGS_KEY = "daily_report_settings"
DEFAULT_DAILY_REPORT_SETTINGS = {
    "report_email_to": "",
    "report_time": "23:00",
    "timezone": "Asia/Beirut",
}


@dataclass
class DailyReportResult:
    sent: bool
    recipient: str
    event_count: int
    subject: str
    generated_at: datetime
    gemini_status: str


class DailyReportEmailService:
    def get_settings(self, db: Session) -> dict:
        setting = db.get(SystemSetting, DAILY_REPORT_SETTINGS_KEY)
        if setting is None:
            return dict(DEFAULT_DAILY_REPORT_SETTINGS)

        value = setting.value or {}
        return {
            "report_email_to": str(value.get("report_email_to") or "").strip(),
            "report_time": str(value.get("report_time") or "23:00").strip(),
            "timezone": str(value.get("timezone") or "Asia/Beirut").strip(),
        }

    def save_settings(self, db: Session, payload: dict) -> dict:
        value = {
            "report_email_to": str(payload.get("report_email_to") or "").strip(),
            "report_time": str(payload.get("report_time") or "23:00").strip(),
            "timezone": str(payload.get("timezone") or "Asia/Beirut").strip() or "Asia/Beirut",
        }
        setting = db.get(SystemSetting, DAILY_REPORT_SETTINGS_KEY)
        if setting is None:
            setting = SystemSetting(
                key=DAILY_REPORT_SETTINGS_KEY,
                value=value,
                description="Daily entry email report settings.",
            )
            db.add(setting)
        else:
            setting.value = value
            setting.description = "Daily entry email report settings."

        db.commit()
        return value

    def send_today_report(self, db: Session) -> DailyReportResult:
        report_settings = self.get_settings(db)
        recipient = report_settings["report_email_to"]
        if not recipient:
            raise ValueError("Set a report recipient email before sending the report.")

        local_zone = self._timezone(report_settings["timezone"])
        now_local = datetime.now(local_zone)
        start_utc, end_utc = self._local_day_bounds(now_local.date(), local_zone)
        events = self._events_between(db, start_utc, end_utc)
        summary = self._build_report_summary(events, now_local.date(), local_zone)
        ai_summary, gemini_status = self._gemini_summary(summary)
        subject = f"Sentry Room Daily Entry Report - {now_local:%Y-%m-%d}"
        body = self._email_body(summary, ai_summary, gemini_status, report_settings)

        self._send_email(recipient=recipient, subject=subject, body=body)
        return DailyReportResult(
            sent=True,
            recipient=recipient,
            event_count=len(events),
            subject=subject,
            generated_at=datetime.now(timezone.utc),
            gemini_status=gemini_status,
        )

    def _events_between(self, db: Session, start_utc: datetime, end_utc: datetime) -> list[AccessEvent]:
        statement = (
            select(AccessEvent)
            .where(AccessEvent.created_at >= start_utc)
            .where(AccessEvent.created_at < end_utc)
            .order_by(AccessEvent.created_at.asc())
        )
        return list(db.scalars(statement))

    def _build_report_summary(
        self,
        events: list[AccessEvent],
        report_date: date,
        local_zone: ZoneInfo,
    ) -> dict:
        categories = [self._event_category(event) for event in events]
        severity_counts = {
            "critical": sum(1 for event in events if event.severity == EventSeverity.CRITICAL),
            "warning": sum(1 for event in events if event.severity == EventSeverity.WARNING),
            "info": sum(1 for event in events if event.severity == EventSeverity.INFO),
        }
        category_counts = {
            "authorized_person": categories.count("authorized_person"),
            "unauthorized_person": categories.count("unauthorized_person"),
            "unknown_face": categories.count("unknown_face"),
            "no_face": categories.count("no_face"),
            "other": sum(
                1
                for category in categories
                if category not in {"authorized_person", "unauthorized_person", "unknown_face", "no_face"}
            ),
        }

        timeline = [
            {
                "time": self._to_local(event.created_at, local_zone).strftime("%H:%M:%S"),
                "type": self._event_label(event),
                "severity": event.severity.value,
                "message": event.message,
                "acknowledged": event.is_acknowledged,
            }
            for event in events
        ]

        return {
            "date": report_date.isoformat(),
            "timezone": str(local_zone),
            "counts": {
                "total_events": len(events),
                "unacknowledged_events": sum(1 for event in events if not event.is_acknowledged),
                **severity_counts,
                **category_counts,
            },
            "timeline": timeline,
        }

    def _gemini_summary(self, summary: dict) -> tuple[str, str]:
        settings = get_settings()
        if not settings.gemini_api_key:
            return self._fallback_summary(summary), "missing_key"

        endpoint = (
            "https://generativelanguage.googleapis.com/v1beta/models/"
            f"{settings.gemini_model}:generateContent"
        )
        compact_timeline = summary["timeline"][-40:]
        payload_for_ai = {
            "date": summary["date"],
            "timezone": summary["timezone"],
            "counts": summary["counts"],
            "timeline": compact_timeline,
        }
        prompt = (
            "You are writing a concise daily security email report for a server room.\n"
            "Use only the supplied facts. Do not invent names, causes, intent, or events.\n"
            "Return plain text with exactly these sections:\n"
            "Executive Summary: 2 short sentences.\n"
            "Key Observations: 3 bullets.\n"
            "Risk Level: Low, Medium, or High with one short reason.\n"
            "Recommended Follow-up: one short action.\n\n"
            f"Daily event data:\n{json.dumps(payload_for_ai, ensure_ascii=True)}"
        )
        request_payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": 0.1,
                "maxOutputTokens": 500,
            },
        }
        request = urllib.request.Request(
            endpoint,
            data=json.dumps(request_payload).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "x-goog-api-key": settings.gemini_api_key,
            },
            method="POST",
        )

        try:
            with urllib.request.urlopen(request, timeout=15) as response:
                decoded = json.loads(response.read().decode("utf-8"))
            text = str(decoded["candidates"][0]["content"]["parts"][0]["text"]).strip()
            return text or self._fallback_summary(summary), "complete"
        except (TimeoutError, OSError, urllib.error.URLError, urllib.error.HTTPError, KeyError, json.JSONDecodeError):
            return self._fallback_summary(summary), "fallback"

    def _fallback_summary(self, summary: dict) -> str:
        counts = summary["counts"]
        if counts["critical"] > 0 or counts["unacknowledged_events"] > 0:
            risk = "High"
        elif counts["warning"] > 0 or counts["unknown_face"] > 0 or counts["no_face"] > 0:
            risk = "Medium"
        else:
            risk = "Low"

        return "\n".join(
            [
                "Executive Summary: Sentry Room generated a database-only daily report. Review the raw event list below for exact activity.",
                "",
                "Key Observations:",
                f"- Total events: {counts['total_events']}",
                f"- Critical events: {counts['critical']}",
                f"- Unacknowledged events: {counts['unacknowledged_events']}",
                f"Risk Level: {risk} based on stored event severity and acknowledgement status.",
                "Recommended Follow-up: Review unacknowledged and critical events first.",
            ]
        )

    def _email_body(self, summary: dict, ai_summary: str, gemini_status: str, report_settings: dict) -> str:
        counts = summary["counts"]
        timeline = summary["timeline"]
        lines = [
            f"Sentry Room Daily Entry Report - {summary['date']}",
            f"Timezone: {summary['timezone']}",
            f"Preferred report time: {report_settings['report_time']}",
            "",
            "Gemini Summary" if gemini_status == "complete" else "Report Summary",
            ai_summary,
            "",
            "Raw Counts",
            f"- Total events: {counts['total_events']}",
            f"- Authorized person events: {counts['authorized_person']}",
            f"- Unauthorized person events: {counts['unauthorized_person']}",
            f"- Unknown face events: {counts['unknown_face']}",
            f"- No-face detections: {counts['no_face']}",
            f"- Critical events: {counts['critical']}",
            f"- Warning events: {counts['warning']}",
            f"- Info events: {counts['info']}",
            f"- Unacknowledged events: {counts['unacknowledged_events']}",
            "",
            "Timeline",
        ]

        if not timeline:
            lines.append("- No events recorded today.")
        else:
            for item in timeline:
                ack = "acknowledged" if item["acknowledged"] else "unacknowledged"
                lines.append(
                    f"- {item['time']} | {item['type']} | {item['severity']} | {ack} | {item['message']}"
                )

        return "\n".join(lines)

    def _send_email(self, recipient: str, subject: str, body: str) -> None:
        settings = get_settings()
        if not all([settings.smtp_host, settings.smtp_username, settings.smtp_password, settings.smtp_from]):
            raise ValueError("SMTP is not configured. Set SMTP_HOST, SMTP_USERNAME, SMTP_PASSWORD, and SMTP_FROM.")

        message = EmailMessage()
        message["Subject"] = subject
        message["From"] = settings.smtp_from
        message["To"] = recipient
        message.set_content(body)

        with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=20) as smtp:
            if settings.smtp_use_tls:
                smtp.starttls(context=ssl.create_default_context())
            smtp.login(settings.smtp_username, settings.smtp_password)
            smtp.send_message(message)

    def _event_category(self, event: AccessEvent) -> str:
        payload = event.sensor_payload or {}
        identity_key = str(payload.get("identity_key") or "")
        detected_face_count = self._number(payload.get("detected_face_count"))
        unknown_face_count = self._number(payload.get("unknown_face_count"))
        identity = self._first_identity(payload)
        status = str(identity.get("status") or "") if identity else ""
        is_authorized = identity.get("is_authorized") if identity else None

        if identity_key == "no_face" or detected_face_count == 0:
            return "no_face"
        if identity_key == "unknown_face" or (unknown_face_count or 0) > 0 or status == "unknown_face":
            return "unknown_face"
        if status == "authorized" or is_authorized is True or event.event_type == EventType.AUTHORIZED_ENTRY:
            return "authorized_person"
        if (
            status == "unauthorized"
            or (is_authorized is False and identity_key.startswith("person_"))
            or (event.event_type == EventType.UNAUTHORIZED_ENTRY and event.person_id is not None)
        ):
            return "unauthorized_person"
        if event.event_type == EventType.UNAUTHORIZED_ENTRY:
            return "unauthorized_entry"
        return "event"

    def _event_label(self, event: AccessEvent) -> str:
        labels = {
            "no_face": "No face visible",
            "unknown_face": "Unknown face",
            "authorized_person": "Authorized person",
            "unauthorized_person": "Unauthorized person",
            "unauthorized_entry": "Unauthorized entry",
        }
        category = self._event_category(event)
        return labels.get(category, event.event_type.value.replace("_", " ").title())

    @staticmethod
    def _first_identity(payload: dict) -> dict | None:
        identities = payload.get("identities")
        if not isinstance(identities, list):
            return None
        for identity in identities:
            if isinstance(identity, dict):
                return identity
        return None

    @staticmethod
    def _number(value: object) -> float | None:
        if isinstance(value, (int, float)):
            return float(value)
        if isinstance(value, str):
            try:
                return float(value)
            except ValueError:
                return None
        return None

    @staticmethod
    def _local_day_bounds(day: date, local_zone: ZoneInfo) -> tuple[datetime, datetime]:
        start_local = datetime.combine(day, time.min, tzinfo=local_zone)
        end_local = start_local + timedelta(days=1)
        return start_local.astimezone(timezone.utc), end_local.astimezone(timezone.utc)

    @staticmethod
    def _to_local(value: datetime, local_zone: ZoneInfo) -> datetime:
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.astimezone(local_zone)

    @staticmethod
    def _timezone(name: str) -> ZoneInfo:
        try:
            return ZoneInfo(name)
        except ZoneInfoNotFoundError:
            return ZoneInfo("Asia/Beirut")
