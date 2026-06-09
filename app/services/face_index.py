from dataclasses import dataclass
from pathlib import Path
import os
import tempfile
import threading

from app.core.config import get_settings


@dataclass(frozen=True)
class IndexedFace:
    person_id: int
    encoding: list[float]


class FaceIndex:
    def __init__(self, path: Path | None = None) -> None:
        self.path = path or get_settings().face_index_path
        self._lock = threading.Lock()

    def load(self) -> list[IndexedFace]:
        numpy = self._numpy()
        if not self.path.exists():
            return []

        data = numpy.load(self.path, allow_pickle=False)
        person_ids = data.get("person_ids")
        encodings = data.get("encodings")
        if person_ids is None or encodings is None:
            return []

        records = []
        for person_id, encoding in zip(person_ids.tolist(), encodings.tolist()):
            records.append(IndexedFace(person_id=int(person_id), encoding=list(encoding)))
        return records

    def add_person_encoding(self, person_id: int, encoding: list[float]) -> None:
        self._validate_encoding(encoding)
        with self._lock:
            records = self.load()
            records.append(IndexedFace(person_id=person_id, encoding=encoding))
            self._save(records)

    def replace_person_encodings(self, person_id: int, encodings: list[list[float]]) -> None:
        for encoding in encodings:
            self._validate_encoding(encoding)

        with self._lock:
            records = [record for record in self.load() if record.person_id != person_id]
            records.extend(IndexedFace(person_id=person_id, encoding=encoding) for encoding in encodings)
            self._save(records)

    def remove_person(self, person_id: int) -> int:
        with self._lock:
            records = self.load()
            kept_records = [record for record in records if record.person_id != person_id]
            removed_count = len(records) - len(kept_records)
            if removed_count:
                self._save(kept_records)
            return removed_count

    def save_event_unknown_encodings(self, event_id: int, encodings: list[list[float]]) -> str | None:
        valid_encodings = []
        for encoding in encodings:
            try:
                self._validate_encoding(encoding)
            except ValueError:
                continue
            valid_encodings.append(encoding)

        if not valid_encodings:
            return None

        numpy = self._numpy()
        path = self._event_faces_path(event_id)
        path.parent.mkdir(parents=True, exist_ok=True)
        numpy.savez_compressed(path, encodings=numpy.asarray(valid_encodings, dtype=float))
        return str(path)

    def load_event_unknown_encodings(self, event_id: int) -> list[list[float]]:
        numpy = self._numpy()
        path = self._event_faces_path(event_id)
        if not path.exists():
            return []

        data = numpy.load(path, allow_pickle=False)
        encodings = data.get("encodings")
        if encodings is None:
            return []
        return [list(encoding) for encoding in encodings.tolist()]

    def _save(self, records: list[IndexedFace]) -> None:
        numpy = self._numpy()
        self.path.parent.mkdir(parents=True, exist_ok=True)

        person_ids = numpy.asarray([record.person_id for record in records], dtype=int)
        encodings = numpy.asarray([record.encoding for record in records], dtype=float)
        if not records:
            encodings = numpy.empty((0, 128), dtype=float)

        fd, temp_name = tempfile.mkstemp(prefix="face_index_", suffix=".npz", dir=str(self.path.parent))
        os.close(fd)
        temp_path = Path(temp_name)
        try:
            numpy.savez_compressed(temp_path, person_ids=person_ids, encodings=encodings)
            os.replace(temp_path, self.path)
        finally:
            if temp_path.exists():
                temp_path.unlink()

    def _event_faces_path(self, event_id: int) -> Path:
        return self.path.parent / "event_faces" / f"event_{event_id}.npz"

    @staticmethod
    def _validate_encoding(encoding: list[float]) -> None:
        if len(encoding) != 128:
            raise ValueError("Face encoding must contain 128 values.")
        if not all(isinstance(value, (int, float)) for value in encoding):
            raise ValueError("Face encoding must contain only numeric values.")

    @staticmethod
    def _numpy():
        try:
            import numpy
        except ImportError as exc:
            raise RuntimeError("numpy is not installed. Install requirements before running face indexing.") from exc
        return numpy


face_index = FaceIndex()
