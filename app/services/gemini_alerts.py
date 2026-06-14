from __future__ import annotations

import base64
import json
import logging
import re
import time
import urllib.error
import urllib.request
from dataclasses import dataclass

from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_modified

from app.core.config import get_settings
from app.models.enums import EventSeverity
from app.models.event import AccessEvent
from app.models.person import Person
from app.models.system import SystemSetting


logger = logging.getLogger(__name__)

AI_ALERT_SETTINGS_KEY = "ai_alert_settings"

DEFAULT_AI_ALERT_SETTINGS = {
    "enabled": True,
    "timeout_seconds": 10,
    "max_words": 10,
    "no_face_prompt": "",
    "unknown_face_prompt": "",
    "known_person_prompt": "",
}


@dataclass(frozen=True)
class AlertPromptContext:
    prompt_case: str
    person_name: str | None = None
    access_status: str | None = None


def get_ai_alert_settings(db: Session) -> dict:
    setting = db.get(SystemSetting, AI_ALERT_SETTINGS_KEY)
    raw_value = setting.value if setting is not None and isinstance(setting.value, dict) else {}
    return _normalize_settings({**DEFAULT_AI_ALERT_SETTINGS, **raw_value})


def save_ai_alert_settings(db: Session, value: dict) -> dict:
    normalized = _normalize_settings({**DEFAULT_AI_ALERT_SETTINGS, **value})
    setting = db.get(SystemSetting, AI_ALERT_SETTINGS_KEY)
    if setting is None:
        setting = SystemSetting(
            key=AI_ALERT_SETTINGS_KEY,
            value=normalized,
            description="Gemini prompt settings for security alert descriptions.",
        )
        db.add(setting)
    else:
        setting.value = normalized
        setting.description = "Gemini prompt settings for security alert descriptions."

    db.commit()
    return normalized


class GeminiAlertService:
    def enrich_event_message(
        self,
        db: Session,
        event: AccessEvent,
        image_bytes: bytes | None,
    ) -> str | None:
        if not self._should_try_event(event, image_bytes):
            return None

        settings = get_settings()
        if not settings.gemini_api_key:
            self._mark_status(event, "skipped", error="GEMINI_API_KEY is not set")
            return None

        prompt_settings = get_ai_alert_settings(db)
        if not prompt_settings["enabled"]:
            self._mark_status(event, "skipped", error="AI alert descriptions disabled")
            return None

        context = self._prompt_context(db, event)
        prompt = self._build_prompt(context, prompt_settings)
        timeout_seconds = float(prompt_settings["timeout_seconds"] or settings.gemini_alert_timeout_seconds)

        started_at = time.perf_counter()
        try:
            raw_text = self._request_description(
                image_bytes=image_bytes or b"",
                prompt=prompt,
                timeout_seconds=timeout_seconds,
            )
        except (TimeoutError, OSError, urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError, KeyError) as exc:
            elapsed_ms = int((time.perf_counter() - started_at) * 1000)
            logger.warning("Gemini alert description failed: %s", exc)
            self._mark_status(event, "failed", error=str(exc), elapsed_ms=elapsed_ms, prompt_case=context.prompt_case)
            return None

        elapsed_ms = int((time.perf_counter() - started_at) * 1000)
        description = self._normalize_description(raw_text, max_words=int(prompt_settings["max_words"]))
        if not description:
            self._mark_status(event, "failed", error="empty Gemini response", elapsed_ms=elapsed_ms, prompt_case=context.prompt_case)
            return None

        event.message = description
        self._mark_status(
            event,
            "complete",
            description=description,
            elapsed_ms=elapsed_ms,
            prompt_case=context.prompt_case,
        )
        return description

    @staticmethod
    def _should_try_event(event: AccessEvent, image_bytes: bytes | None) -> bool:
        if event.severity == EventSeverity.INFO:
            return False
        if not image_bytes:
            return False
        return len(image_bytes) > 10 and image_bytes.startswith(b"\xff\xd8\xff")

    def _request_description(self, image_bytes: bytes, prompt: str, timeout_seconds: float) -> str:
        settings = get_settings()
        endpoint = f"https://generativelanguage.googleapis.com/v1beta/models/{settings.gemini_model}:generateContent"
        payload = {
            "contents": [
                {
                    "parts": [
                        {
                            "inline_data": {
                                "mime_type": "image/jpeg",
                                "data": base64.b64encode(image_bytes).decode("ascii"),
                            }
                        },
                        {"text": prompt},
                    ]
                }
            ],
            "generationConfig": {
                "temperature": 0,
                "maxOutputTokens": 40,
            },
        }
        request = urllib.request.Request(
            endpoint,
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "x-goog-api-key": settings.gemini_api_key or "",
            },
            method="POST",
        )

        with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
            decoded = json.loads(response.read().decode("utf-8"))

        return str(decoded["candidates"][0]["content"]["parts"][0]["text"])

    def _prompt_context(self, db: Session, event: AccessEvent) -> AlertPromptContext:
        payload = event.sensor_payload or {}
        identity_key = str(payload.get("identity_key") or "")

        if identity_key == "no_face" or payload.get("detected_face_count") == 0:
            return AlertPromptContext(prompt_case="no_face")

        if identity_key == "unknown_face" or int(payload.get("unknown_face_count") or 0) > 0:
            return AlertPromptContext(prompt_case="unknown_face")

        person = db.get(Person, event.person_id) if event.person_id is not None else None
        if person is not None:
            return AlertPromptContext(
                prompt_case="known_person",
                person_name=person.full_name,
                access_status="authorized" if person.is_authorized else "unauthorized",
            )

        identity = self._first_named_identity(payload)
        if identity is not None:
            return AlertPromptContext(
                prompt_case="known_person",
                person_name=str(identity.get("name") or "Known person"),
                access_status=str(identity.get("status") or "known"),
            )

        return AlertPromptContext(prompt_case="unknown_face")

    @staticmethod
    def _first_named_identity(payload: dict) -> dict | None:
        identities = payload.get("identities")
        if not isinstance(identities, list):
            return None
        for identity in identities:
            if isinstance(identity, dict) and identity.get("name"):
                return identity
        return None

    @staticmethod
    def _build_prompt(context: AlertPromptContext, prompt_settings: dict) -> str:
        max_words = int(prompt_settings["max_words"])

        if context.prompt_case == "known_person":
            name = context.person_name or "Known person"
            status = context.access_status or "known"
            extra = str(prompt_settings.get("known_person_prompt") or "").strip()
            return _prompt_with_extra(
                base=(
                    "Security camera alert.\n"
                    f"{name} was detected. Access status: {status}.\n"
                    f"Say the person's name and describe what they appear to be doing in under {max_words} words.\n"
                    "Do not guess age, gender, race, emotion, or intent.\n"
                    "Return only the alert text."
                ),
                extra=extra,
            )

        if context.prompt_case == "no_face":
            extra = str(prompt_settings.get("no_face_prompt") or "").strip()
            return _prompt_with_extra(
                base=(
                    "Security camera alert.\n"
                    "A person was detected but their face is not visible.\n"
                    f"Describe their clothing and what they appear to be doing in under {max_words} words.\n"
                    "Do not guess identity, age, gender, race, emotion, or intent.\n"
                    "If no person is visible, reply exactly: no person.\n"
                    "Return only the alert text."
                ),
                extra=extra,
            )

        extra = str(prompt_settings.get("unknown_face_prompt") or "").strip()
        return _prompt_with_extra(
            base=(
                "Security camera alert.\n"
                "An unknown person was detected.\n"
                f"Describe their clothing and what they appear to be doing in under {max_words} words.\n"
                "Do not guess identity, age, gender, race, emotion, or intent.\n"
                "If no person is visible, reply exactly: no person.\n"
                "Return only the alert text."
            ),
            extra=extra,
        )

    @staticmethod
    def _normalize_description(description: str, max_words: int) -> str | None:
        text = " ".join(description.replace("\n", " ").split())
        text = text.strip(" -_*`\"'")
        if not text:
            return None

        text = re.split(r"(?<=[.!?])\s+", text, maxsplit=1)[0].strip()
        normalized = text.strip(" .!?:;").lower()
        if normalized == "security camera alert" or normalized.startswith("security camera alert "):
            return None

        words = text.split()
        if len(words) > max_words:
            text = " ".join(words[:max_words]).strip(" ,;:-")

        return text or None

    @staticmethod
    def _mark_status(
        event: AccessEvent,
        status: str,
        *,
        description: str | None = None,
        error: str | None = None,
        elapsed_ms: int | None = None,
        prompt_case: str | None = None,
    ) -> None:
        payload = event.sensor_payload or {}
        payload["ai_alert"] = {
            "provider": "gemini",
            "status": status,
            "description": description,
            "error": error,
            "elapsed_ms": elapsed_ms,
            "prompt_case": prompt_case,
        }
        event.sensor_payload = payload
        flag_modified(event, "sensor_payload")


def _normalize_settings(value: dict) -> dict:
    return {
        "enabled": bool(value.get("enabled", True)),
        "timeout_seconds": _clamp_float(value.get("timeout_seconds"), 1, 30, 10),
        "max_words": int(_clamp_float(value.get("max_words"), 4, 20, 10)),
        "no_face_prompt": _clean_prompt(value.get("no_face_prompt")),
        "unknown_face_prompt": _clean_prompt(value.get("unknown_face_prompt")),
        "known_person_prompt": _clean_prompt(value.get("known_person_prompt")),
    }


def _clamp_float(value: object, minimum: float, maximum: float, default: float) -> float:
    try:
        parsed = float(value)
    except (TypeError, ValueError):
        return default
    return min(max(parsed, minimum), maximum)


def _clean_prompt(value: object) -> str:
    if not isinstance(value, str):
        return ""
    return " ".join(value.split())[:500]


def _prompt_with_extra(base: str, extra: str) -> str:
    if not extra:
        return base
    return f"{base}\n\nExtra user instruction:\n{extra}"


gemini_alert_service = GeminiAlertService()
