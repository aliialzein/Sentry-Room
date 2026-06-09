from pathlib import Path
import json
import os
import subprocess
import sys
import tempfile

from app.core.config import PROJECT_ROOT, get_settings


def encoding_from_image_isolated(image_bytes: bytes) -> list[float]:
    settings = get_settings()
    temp_path: Path | None = None

    try:
        with tempfile.NamedTemporaryFile(prefix="sentry_face_", suffix=".jpg", delete=False) as temp_file:
            temp_file.write(image_bytes)
            temp_path = Path(temp_file.name)

        env = {
            **os.environ,
            "OMP_NUM_THREADS": "1",
            "OPENBLAS_NUM_THREADS": "1",
            "MKL_NUM_THREADS": "1",
            "NUMEXPR_NUM_THREADS": "1",
        }
        result = subprocess.run(
            [
                sys.executable,
                str(PROJECT_ROOT / "scripts" / "face_encode_image.py"),
                str(temp_path),
                "--model",
                settings.face_detection_model,
                "--upsample",
                str(settings.face_detection_upsample),
            ],
            capture_output=True,
            env=env,
            text=True,
            timeout=20,
        )
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError("Face encoding timed out.") from exc
    finally:
        if temp_path is not None and temp_path.exists():
            temp_path.unlink()

    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        if result.returncode < 0 or result.returncode == 139:
            raise RuntimeError("Face encoder crashed in an isolated process.")
        if result.returncode in {2, 3}:
            raise ValueError(detail or "Face enrollment image was not usable.")
        raise RuntimeError(detail or "Face encoder failed.")

    try:
        payload = json.loads(result.stdout)
        encoding = payload["encoding"]
    except (json.JSONDecodeError, KeyError, TypeError) as exc:
        raise RuntimeError("Face encoder returned invalid output.") from exc

    if not isinstance(encoding, list) or len(encoding) != 128:
        raise RuntimeError("Face encoder returned an invalid encoding.")

    return [float(value) for value in encoding]
