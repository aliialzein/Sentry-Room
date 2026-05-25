from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4
import base64
import binascii

from app.core.config import PROJECT_ROOT, get_settings


def decode_base64_payload(payload: str) -> bytes:
    if "," in payload:
        payload = payload.split(",", 1)[1]

    try:
        return base64.b64decode(payload, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise ValueError("Invalid base64 payload.") from exc


def save_bytes_file(
    content: bytes,
    subdir: str,
    filename_prefix: str,
    suffix: str = ".jpg",
) -> str:
    settings = get_settings()
    target_dir = settings.evidence_dir / subdir
    target_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    filename = f"{filename_prefix}_{timestamp}_{uuid4().hex[:8]}{suffix}"
    path = target_dir / filename
    path.write_bytes(content)
    return _project_relative(path)


def _project_relative(path: Path) -> str:
    try:
        return str(path.resolve().relative_to(PROJECT_ROOT))
    except ValueError:
        return str(path)
