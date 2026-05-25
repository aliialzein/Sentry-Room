from dataclasses import asdict, dataclass
from random import uniform


@dataclass(frozen=True)
class SensorSnapshot:
    motion_detected: bool
    temperature_c: float | None = None
    humidity_percent: float | None = None
    distance_cm: float | None = None

    def as_payload(self) -> dict:
        return asdict(self)


class SimulatedSensorProvider:
    def read(self, motion_detected: bool = True) -> SensorSnapshot:
        return SensorSnapshot(
            motion_detected=motion_detected,
            temperature_c=round(uniform(20.0, 28.0), 1),
            humidity_percent=round(uniform(35.0, 65.0), 1),
            distance_cm=round(uniform(40.0, 250.0), 1),
        )
