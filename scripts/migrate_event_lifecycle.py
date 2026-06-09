from pathlib import Path
import sys

from sqlalchemy import text


sys.path.append(str(Path(__file__).resolve().parents[1]))

from app.core.database import engine


def main() -> None:
    statements = [
        "ALTER TABLE access_events ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ",
        "ALTER TABLE access_events ADD COLUMN IF NOT EXISTS ended_at TIMESTAMPTZ",
        "UPDATE access_events SET last_seen_at = created_at WHERE last_seen_at IS NULL",
        (
            "UPDATE access_events SET ended_at = created_at "
            "WHERE ended_at IS NULL AND ("
            "(sensor_payload->>'source') IS DISTINCT FROM 'person_detection_worker' "
            "OR sensor_payload->>'identity_key' IS NULL"
            ")"
        ),
        "CREATE INDEX IF NOT EXISTS ix_access_events_last_seen_at ON access_events (last_seen_at)",
        "CREATE INDEX IF NOT EXISTS ix_access_events_ended_at ON access_events (ended_at)",
    ]

    with engine.begin() as connection:
        for statement in statements:
            connection.execute(text(statement))

    print("Event lifecycle migration complete.")


if __name__ == "__main__":
    main()
