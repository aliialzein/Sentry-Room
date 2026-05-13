from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path
import os


PROJECT_ROOT = Path(__file__).resolve().parents[2]

try:
    from dotenv import load_dotenv

    load_dotenv(PROJECT_ROOT / ".env")
except ImportError:
    pass


def _bool_env(name: str, default: bool) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _path_env(name: str, default: Path) -> Path:
    value = os.getenv(name)
    path = Path(value) if value else default
    return path if path.is_absolute() else PROJECT_ROOT / path


@dataclass(frozen=True)
class Settings:
    app_name: str = os.getenv("APP_NAME", "Sentry Room")
    environment: str = os.getenv("ENVIRONMENT", "development")
    debug: bool = field(default_factory=lambda: _bool_env("DEBUG", True))

    database_url: str = os.getenv(
        "DATABASE_URL",
        "postgresql+psycopg2://postgres:postgres@localhost:5432/sentry_room",
    )

    evidence_dir: Path = field(default_factory=lambda: _path_env("EVIDENCE_DIR", PROJECT_ROOT / "data" / "evidence"))
    legacy_faces_db: Path = field(
        default_factory=lambda: _path_env("LEGACY_FACES_DB", PROJECT_ROOT / "data" / "legacy" / "faces_db.pkl")
    )

    face_match_tolerance: float = float(os.getenv("FACE_MATCH_TOLERANCE", "0.5"))
    alert_email_to: str | None = os.getenv("ALERT_EMAIL_TO")
    app_alert_channel: str = os.getenv("APP_ALERT_CHANNEL", "mobile_app")


@lru_cache
def get_settings() -> Settings:
    return Settings()
