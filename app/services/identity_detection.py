from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.person import Person
from app.services.face_index import FaceIndex, face_index
from app.services.recognition import FaceRecognitionService, KnownFace


@dataclass(frozen=True)
class FaceIdentity:
    status: str
    location: tuple[int, int, int, int]
    person_id: int | None = None
    name: str | None = None
    is_authorized: bool | None = None
    confidence: float | None = None
    distance: float | None = None
    encoding: list[float] | None = None


@dataclass(frozen=True)
class IdentityDetectionResult:
    detected_face_count: int
    identities: list[FaceIdentity]

    @property
    def unknown_encodings(self) -> list[list[float]]:
        return [
            identity.encoding
            for identity in self.identities
            if identity.status == "unknown_face" and identity.encoding is not None
        ]

    @property
    def primary_identity(self) -> FaceIdentity | None:
        if not self.identities:
            return None

        priority = {
            "unauthorized": 0,
            "unknown_face": 1,
            "authorized": 2,
        }
        return sorted(self.identities, key=lambda identity: priority.get(identity.status, 99))[0]


class IdentityDetectionService:
    def __init__(
        self,
        recognizer: FaceRecognitionService | None = None,
        index: FaceIndex | None = None,
    ) -> None:
        self.recognizer = recognizer or FaceRecognitionService()
        self.index = index or face_index

    def recognize(self, db: Session, image_bytes: bytes) -> IdentityDetectionResult:
        detected_faces = self.recognizer.detect_faces(image_bytes)
        if not detected_faces:
            return IdentityDetectionResult(detected_face_count=0, identities=[])

        people_by_id = self._people_by_id(db)
        known_faces = [
            KnownFace(
                name=people_by_id[indexed.person_id].full_name,
                encoding=indexed.encoding,
                person_id=indexed.person_id,
            )
            for indexed in self.index.load()
            if indexed.person_id in people_by_id
        ]

        identities = []
        for detected_face in detected_faces:
            match = self.recognizer.match_encoding(known_faces, detected_face.encoding)
            if match is None or match.person_id is None or match.person_id not in people_by_id:
                identities.append(
                    FaceIdentity(
                        status="unknown_face",
                        location=detected_face.location,
                        encoding=detected_face.encoding,
                    )
                )
                continue

            person = people_by_id[match.person_id]
            identities.append(
                FaceIdentity(
                    status="authorized" if person.is_authorized else "unauthorized",
                    location=detected_face.location,
                    person_id=person.id,
                    name=person.full_name,
                    is_authorized=person.is_authorized,
                    confidence=match.confidence,
                    distance=match.distance,
                )
            )

        return IdentityDetectionResult(
            detected_face_count=len(detected_faces),
            identities=identities,
        )

    @staticmethod
    def _people_by_id(db: Session) -> dict[int, Person]:
        people = db.scalars(select(Person)).all()
        return {person.id: person for person in people}
