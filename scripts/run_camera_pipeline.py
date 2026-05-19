from pathlib import Path
import argparse
import sys
import time


sys.path.append(str(Path(__file__).resolve().parents[1]))

from app.iot.camera import find_camera
from app.iot.pipeline import SentryPipeline
from app.iot.sensors import SimulatedSensorProvider
from app.services.recognition import FaceRecognitionService


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the webcam detection pipeline.")
    parser.add_argument("--burst-frames", type=int, default=6, help="Frames to sample before processing one event")
    parser.add_argument("--interval", type=float, default=3.0, help="Seconds between processed bursts")
    args = parser.parse_args()

    capture = find_camera()
    if capture is None:
        raise SystemExit("No camera found.")

    pipeline = SentryPipeline()
    sensors = SimulatedSensorProvider()
    recognizer = FaceRecognitionService()

    try:
        while True:
            frame, face_count = _best_frame_from_burst(capture, recognizer, args.burst_frames)
            if frame is None:
                print("Failed to capture frame.")
                break

            payload = sensors.read(motion_detected=True).as_payload()
            payload["candidate_face_count"] = face_count
            result = pipeline.process_snapshot(frame, payload)
            print(f"{result.event_type} | {result.severity} | faces={face_count} | {result.message}")
            time.sleep(args.interval)
    finally:
        capture.release()


def _best_frame_from_burst(capture, recognizer: FaceRecognitionService, frame_count: int) -> tuple[bytes | None, int]:
    cv2 = _cv2()
    best_frame = None
    best_face_count = -1
    first_frame = None

    for _ in range(max(1, frame_count)):
        success, frame = capture.read()
        if not success:
            continue

        encoded, buffer = cv2.imencode(".jpg", frame)
        if not encoded:
            continue

        frame_bytes = buffer.tobytes()
        first_frame = first_frame or frame_bytes
        face_count = len(recognizer.detect_faces(frame_bytes))
        if face_count > best_face_count:
            best_frame = frame_bytes
            best_face_count = face_count

        if face_count > 0:
            break

        time.sleep(0.15)

    return best_frame or first_frame, max(0, best_face_count)


def _cv2():
    try:
        import cv2
    except ImportError as exc:
        raise SystemExit("opencv-python is not installed. Install requirements-ai.txt first.") from exc
    return cv2


if __name__ == "__main__":
    main()
