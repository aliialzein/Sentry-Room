from __future__ import annotations

import json
import logging
import urllib.error
import urllib.request
from dataclasses import dataclass
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models.enums import EventSeverity, EventType
from app.models.event import AccessEvent
from app.services.event_messages import websocket_event_message
from app.services.notification import NotificationService
from app.services.pi_camera_stream import pi_camera_stream
from app.services.storage import save_bytes_file

logger = logging.getLogger(__name__)


@dataclass
class FireVisionResult:
    fire_visible: bool
    smoke_visible: bool
    risk: str
    reason: str
    status: str = "complete"
    error: str | None = None


class FireRiskService:
    def process_pi_trigger(self, db: Session, payload: dict) -> AccessEvent:
        frame = pi_camera_stream.latest_frame()
        snapshot_path = None
        vision = FireVisionResult(
            fire_visible=False,
            smoke_visible=False,
            risk="medium",
            reason="Sensor fire-risk trigger received.",
            status="fallback",
        )

        if frame is not None:
            snapshot_path = save_bytes_file(
                frame,
                subdir="events",
                filename_prefix="fire_risk",
            )
            vision = self._analyze_snapshot(frame, payload)
        else:
            vision.error = "No camera frame available."

        is_emergency = (
            vision.risk.lower() == "high"
            or vision.fire_visible
            or vision.smoke_visible
        )
        severity = EventSeverity.CRITICAL if is_emergency else EventSeverity.WARNING
        message = self._message(payload, vision, is_emergency)

        event = AccessEvent(
            event_type=EventType.ENVIRONMENTAL_ALERT,
            severity=severity,
            message=message,
            snapshot_path=snapshot_path,
            sensor_payload=self._sensor_payload(payload, vision, is_emergency),
        )
        db.add(event)
        db.flush()
        NotificationService().create_pending_alerts(db, event)
        return event

    def websocket_message(self, event: AccessEvent) -> dict:
        message = websocket_event_message(event)
        message["emergency_type"] = "fire"
        return message

    def _analyze_snapshot(self, image_bytes: bytes, payload: dict) -> FireVisionResult:
        settings = get_settings()
        if not settings.gemini_api_key:
            return FireVisionResult(
                fire_visible=False,
                smoke_visible=False,
                risk="medium",
                reason="Gemini key missing; sensor trigger only.",
                status="missing_key",
            )

        endpoint = (
            "https://generativelanguage.googleapis.com/v1beta/models/"
            f"{settings.gemini_model}:generateContent"
        )
        prompt = (
            "Server room fire safety check.\n"
            "Use only visible evidence in the image and the supplied sensor trigger.\n"
            "Look for visible flame, smoke, haze, bright fire-like glow, or overheating evidence.\n"
            "Return JSON only with keys fire_visible, smoke_visible, risk, reason.\n"
            "risk must be low, medium, or high. reason must be under 12 words.\n\n"
            f"Sensor trigger:\n{json.dumps(self._compact_payload(payload), ensure_ascii=True)}"
        )
        request_payload = {
            "contents": [
                {
                    "parts": [
                        {
                            "inline_data": {
                                "mime_type": "image/jpeg",
                                "data": self._b64(image_bytes),
                            }
                        },
                        {"text": prompt},
                    ]
                }
            ],
            "generationConfig": {
                "temperature": 0,
                "maxOutputTokens": 120,
                "responseMimeType": "application/json",
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
            with urllib.request.urlopen(request, timeout=12) as response:
                decoded = json.loads(response.read().decode("utf-8"))
            content = str(decoded["candidates"][0]["content"]["parts"][0]["text"])
            parsed = json.loads(content)
            risk = str(parsed.get("risk") or "medium").lower()
            if risk not in {"low", "medium", "high"}:
                risk = "medium"
            return FireVisionResult(
                fire_visible=bool(parsed.get("fire_visible")),
                smoke_visible=bool(parsed.get("smoke_visible")),
                risk=risk,
                reason=str(parsed.get("reason") or "Fire-risk image check completed.").strip()[:120],
            )
        except (TimeoutError, OSError, urllib.error.URLError, urllib.error.HTTPError, KeyError, json.JSONDecodeError) as exc:
            logger.warning("Gemini fire-risk check failed: %s", exc)
            return FireVisionResult(
                fire_visible=False,
                smoke_visible=False,
                risk="medium",
                reason="Gemini unavailable; sensor trigger only.",
                status="fallback",
                error=str(exc),
            )

    def _message(self, payload: dict, vision: FireVisionResult, is_emergency: bool) -> str:
        temp = self._fmt(payload.get("temperature_c"), "C")
        light = self._fmt(payload.get("light_value") or payload.get("light"), "")
        prefix = "Fire emergency risk" if is_emergency else "Possible fire risk"
        details = []
        if temp:
            details.append(f"temperature {temp}")
        if light:
            details.append(f"light {light}")
        detail_text = ", ".join(details) if details else "sensor trigger received"
        return f"{prefix}: {detail_text}. Gemini: {vision.reason}"

    def _sensor_payload(self, payload: dict, vision: FireVisionResult, is_emergency: bool) -> dict:
        return {
            "source": "pi_fire_risk",
            "emergency_type": "fire",
            "fire_risk": {
                "trigger": self._compact_payload(payload),
                "is_emergency": is_emergency,
                "gemini": {
                    "fire_visible": vision.fire_visible,
                    "smoke_visible": vision.smoke_visible,
                    "risk": vision.risk,
                    "reason": vision.reason,
                    "status": vision.status,
                    "error": vision.error,
                },
                "processed_at": datetime.now(timezone.utc).isoformat(),
            },
        }

    @staticmethod
    def _compact_payload(payload: dict) -> dict:
        return {
            "temperature_c": payload.get("temperature_c"),
            "humidity_percent": payload.get("humidity_percent"),
            "light_value": payload.get("light_value") or payload.get("light"),
            "trigger_reason": payload.get("trigger_reason") or payload.get("reason") or "pi_fire_risk",
            "source": payload.get("source") or "pi_fire_risk",
            "timestamp": payload.get("timestamp"),
        }

    @staticmethod
    def _fmt(value: object, suffix: str) -> str:
        if value is None:
            return ""
        if isinstance(value, (int, float)):
            return f"{value:g}{suffix}"
        return f"{value}{suffix}"

    @staticmethod
    def _b64(content: bytes) -> str:
        import base64

        return base64.b64encode(content).decode("ascii")


fire_risk_service = FireRiskService()
