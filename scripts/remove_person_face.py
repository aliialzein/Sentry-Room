from pathlib import Path
import argparse
import sys


sys.path.append(str(Path(__file__).resolve().parents[1]))

from app.core.database import SessionLocal
from app.models.person import Person
from app.services.face_index import face_index


def main() -> None:
    parser = argparse.ArgumentParser(description="Remove a person's local face encoding without deleting the person row.")
    parser.add_argument("person_id", type=int, help="Person id whose encoding should be removed from face_index.npz")
    args = parser.parse_args()

    db = SessionLocal()
    try:
        person = db.get(Person, args.person_id)
        if person is None:
            raise SystemExit(f"Person {args.person_id} was not found.")

        removed_count = face_index.remove_person(person.id)
    finally:
        db.close()

    print(f"Removed {removed_count} face encoding(s) for person {args.person_id}.")


if __name__ == "__main__":
    main()
