from dataclasses import dataclass
from pathlib import Path
import pickle

from app.core.config import get_settings


@dataclass(frozen=True)
class LegacyFaceRecord:
    name: str
    encoding: list[float]


class LegacyFaceStore:
    def __init__(self, path: Path | None = None) -> None:
        self.path = path or get_settings().legacy_faces_db

    def load(self) -> list[LegacyFaceRecord]:
        if not self.path.exists():
            return []

        with self.path.open("rb") as file:
            raw_db = pickle.load(file)

        names = raw_db.get("names", [])
        encodings = raw_db.get("encodings", [])
        records = []
        for name, encoding in zip(names, encodings):
            if hasattr(encoding, "tolist"):
                encoding = encoding.tolist()
            records.append(LegacyFaceRecord(name=name, encoding=list(encoding)))
        return records

    def save(self, records: list[LegacyFaceRecord]) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        payload = {
            "names": [record.name for record in records],
            "encodings": [record.encoding for record in records],
        }
        with self.path.open("wb") as file:
            pickle.dump(payload, file)

    def add(self, name: str, encoding: list[float]) -> None:
        records = self.load()
        records.append(LegacyFaceRecord(name=name, encoding=encoding))
        self.save(records)
