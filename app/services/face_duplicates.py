from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models.person import Person
from app.services.face_index import face_index


@dataclass(frozen=True)
class ExistingFaceMatch:
    person_id: int
    name: str
    distance: float
    confidence: float


def find_existing_face_match(
    db: Session,
    encoding: list[float],
    exclude_person_id: int | None = None,
) -> ExistingFaceMatch | None:
    numpy = _numpy()
    tolerance = get_settings().face_match_tolerance
    candidate_encoding = numpy.asarray(encoding, dtype=float)
    if candidate_encoding.shape != (128,):
        return None

    people_by_id = {person.id: person for person in db.scalars(select(Person))}
    best_match: ExistingFaceMatch | None = None

    for indexed_face in face_index.load():
        if indexed_face.person_id == exclude_person_id:
            continue
        person = people_by_id.get(indexed_face.person_id)
        if person is None:
            continue
        best_match = _closer_match(
            best_match,
            _match_person(numpy, person, indexed_face.encoding, candidate_encoding, tolerance),
        )

    for person in people_by_id.values():
        if person.id == exclude_person_id or not _is_valid_face_encoding(person.face_encoding):
            continue
        best_match = _closer_match(
            best_match,
            _match_person(numpy, person, person.face_encoding or [], candidate_encoding, tolerance),
        )

    return best_match


def _match_person(numpy, person: Person, encoding: list[float], candidate_encoding, tolerance: float) -> ExistingFaceMatch | None:
    known_encoding = numpy.asarray(encoding, dtype=float)
    if known_encoding.shape != (128,):
        return None

    distance = float(numpy.linalg.norm(known_encoding - candidate_encoding))
    if distance > tolerance:
        return None

    return ExistingFaceMatch(
        person_id=person.id,
        name=person.full_name,
        distance=distance,
        confidence=max(0.0, min(1.0, 1.0 - distance)),
    )


def _closer_match(
    current: ExistingFaceMatch | None,
    candidate: ExistingFaceMatch | None,
) -> ExistingFaceMatch | None:
    if candidate is None:
        return current
    if current is None or candidate.distance < current.distance:
        return candidate
    return current


def _is_valid_face_encoding(encoding: object) -> bool:
    if not isinstance(encoding, list) or len(encoding) != 128:
        return False
    return all(isinstance(value, (int, float)) for value in encoding)


def _numpy():
    try:
        import numpy
    except ImportError as exc:
        raise RuntimeError("numpy is not installed. Install requirements before checking duplicate faces.") from exc
    return numpy
