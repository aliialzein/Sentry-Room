from pathlib import Path
import sys


sys.path.append(str(Path(__file__).resolve().parents[1]))

from app.core.database import SessionLocal
from app.models.person import Person
from app.services.face_store import LegacyFaceStore


def main() -> None:
    records = LegacyFaceStore().load()
    db = SessionLocal()
    try:
        imported = 0
        for record in records:
            person = Person(
                full_name=record.name,
                is_authorized=True,
                face_encoding=record.encoding,
                notes="Imported from legacy faces_db.pkl.",
            )
            db.add(person)
            imported += 1
        db.commit()
    finally:
        db.close()

    print(f"Imported {imported} face record(s).")


if __name__ == "__main__":
    main()
