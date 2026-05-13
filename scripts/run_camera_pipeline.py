from pathlib import Path
import sys
import time


sys.path.append(str(Path(__file__).resolve().parents[1]))

from app.iot.camera import find_camera, jpeg_frames
from app.iot.pipeline import SentryPipeline
from app.iot.sensors import SimulatedSensorProvider


def main() -> None:
    capture = find_camera()
    if capture is None:
        raise SystemExit("No camera found.")

    pipeline = SentryPipeline()
    sensors = SimulatedSensorProvider()

    try:
        for frame in jpeg_frames(capture):
            payload = sensors.read(motion_detected=True).as_payload()
            result = pipeline.process_snapshot(frame, payload)
            print(f"{result.event_type} | {result.severity} | {result.message}")
            time.sleep(5)
    finally:
        capture.release()


if __name__ == "__main__":
    main()
