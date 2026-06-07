from __future__ import annotations

import base64
import json
import logging
import re
import threading
import urllib.error
import urllib.request

from app.core.config import Settings, get_settings


logger = logging.getLogger(__name__)

SECURITY_NOTIFICATION_PROMPT = (
    "Security camera alert. Output only one plain sentence under 14 words. "
    "Mention visible people, clothing, and action only. No extra text."
)


class VisionDescriptionService:
    def __init__(self, settings: Settings | None = None) -> None:
        self._settings = settings or get_settings()
        self._lock = threading.Lock()

    def describe_frame(self, image_bytes: bytes) -> str | None:
        if not self._settings.vision_description_enabled:
            return None
        if not self._lock.acquire(blocking=False):
            logger.info("Vision description skipped because the model is already busy")
            return None

        try:
            raw_description = self._request_description(image_bytes)
        except (TimeoutError, OSError, urllib.error.URLError, json.JSONDecodeError, KeyError):
            logger.exception("Vision description failed")
            return None
        finally:
            self._lock.release()

        return self._normalize_description(raw_description)

    def _request_description(self, image_bytes: bytes) -> str:
        endpoint = self._settings.ollama_base_url.rstrip("/") + "/api/generate"
        payload = {
            "model": self._settings.ollama_vision_model,
            "prompt": SECURITY_NOTIFICATION_PROMPT,
            "images": [base64.b64encode(image_bytes).decode("ascii")],
            "stream": False,
            "options": {
                "num_predict": 30,
                "temperature": 0.2,
            },
        }
        request = urllib.request.Request(
            endpoint,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )

        with urllib.request.urlopen(
            request,
            timeout=self._settings.vision_description_timeout_seconds,
        ) as response:
            decoded = json.loads(response.read().decode("utf-8"))

        return str(decoded["response"])

    def _normalize_description(self, description: str) -> str | None:
        text = " ".join(description.replace("\n", " ").split())
        text = text.strip(" -_*`\"'")
        if not text:
            return None

        first_sentence = re.split(r"(?<=[.!?])\s+", text, maxsplit=1)[0]
        if first_sentence:
            text = first_sentence

        max_chars = max(40, self._settings.vision_description_max_chars)
        if len(text) > max_chars:
            trimmed = text[: max_chars + 1].rsplit(" ", 1)[0].strip(" ,;:-")
            text = trimmed if trimmed else text[:max_chars].strip()
            if text and text[-1] not in ".!?":
                text += "."

        return text


vision_description_service = VisionDescriptionService()
