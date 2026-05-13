from __future__ import annotations

from dataclasses import dataclass
from io import BytesIO
from typing import Sequence

from app.core.config import get_settings


@dataclass(frozen=True)
class DetectedFace:
    encoding: list[float]
    location: tuple[int, int, int, int]


@dataclass(frozen=True)
class KnownFace:
    name: str
    encoding: Sequence[float]
    person_id: int | None = None


@dataclass(frozen=True)
class FaceMatch:
    name: str
    person_id: int | None
    distance: float
    confidence: float


class FaceRecognitionService:
    def __init__(self, tolerance: float | None = None) -> None:
        self.tolerance = tolerance if tolerance is not None else get_settings().face_match_tolerance

    def detect_faces(self, image_bytes: bytes) -> list[DetectedFace]:
        face_recognition = self._face_recognition()
        image = face_recognition.load_image_file(BytesIO(image_bytes))
        locations = face_recognition.face_locations(image)
        encodings = face_recognition.face_encodings(image, locations)
        return [
            DetectedFace(encoding=encoding.tolist(), location=tuple(location))
            for encoding, location in zip(encodings, locations)
        ]

    def encoding_from_image(self, image_bytes: bytes) -> list[float]:
        detected_faces = self.detect_faces(image_bytes)
        if not detected_faces:
            raise ValueError("No face detected in the image.")
        if len(detected_faces) > 1:
            raise ValueError("Multiple faces detected. Enrollment requires exactly one face.")
        return detected_faces[0].encoding

    def match_encoding(self, known_faces: list[KnownFace], encoding: Sequence[float]) -> FaceMatch | None:
        if not known_faces:
            return None

        face_recognition = self._face_recognition()
        numpy = self._numpy()
        known_encodings = [known_face.encoding for known_face in known_faces]
        distances = face_recognition.face_distance(known_encodings, encoding)
        best_index = int(numpy.argmin(distances))
        best_distance = float(distances[best_index])

        if best_distance > self.tolerance:
            return None

        confidence = max(0.0, min(1.0, 1.0 - best_distance))
        known_face = known_faces[best_index]
        return FaceMatch(
            name=known_face.name,
            person_id=known_face.person_id,
            distance=best_distance,
            confidence=confidence,
        )

    @staticmethod
    def _face_recognition():
        try:
            import face_recognition
        except ImportError as exc:
            raise RuntimeError("face-recognition is not installed. Install requirements before running AI detection.") from exc
        return face_recognition

    @staticmethod
    def _numpy():
        try:
            import numpy
        except ImportError as exc:
            raise RuntimeError("numpy is not installed. Install requirements before running AI detection.") from exc
        return numpy
