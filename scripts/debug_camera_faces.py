from pathlib import Path
import sys


sys.path.append(str(Path(__file__).resolve().parents[1]))

from app.core.config import get_settings
from app.iot.camera import find_camera


def main() -> None:
    cv2 = _cv2()
    face_recognition = _face_recognition()
    settings = get_settings()

    capture = find_camera()
    if capture is None:
        raise SystemExit("No camera found.")

    print("Camera debug started. Press Q to quit, SPACE to save a frame.")
    print(f"Detection model={settings.face_detection_model}, upsample={settings.face_detection_upsample}")

    saved_count = 0
    try:
        while True:
            success, frame = capture.read()
            if not success:
                print("Failed to read frame.")
                break

            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            locations = face_recognition.face_locations(
                rgb_frame,
                number_of_times_to_upsample=settings.face_detection_upsample,
                model=settings.face_detection_model,
            )

            for top, right, bottom, left in locations:
                cv2.rectangle(frame, (left, top), (right, bottom), (0, 255, 0), 2)

            cv2.putText(
                frame,
                f"Faces: {len(locations)}",
                (10, 30),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.8,
                (0, 255, 255),
                2,
            )
            cv2.imshow("Sentry Room Face Debug", frame)

            key = cv2.waitKey(1) & 0xFF
            if key == ord("q"):
                break
            if key == ord(" "):
                saved_count += 1
                output_path = Path("data") / "evidence" / f"debug_face_{saved_count}.jpg"
                output_path.parent.mkdir(parents=True, exist_ok=True)
                cv2.imwrite(str(output_path), frame)
                print(f"Saved {output_path}")
    finally:
        capture.release()
        cv2.destroyAllWindows()


def _cv2():
    try:
        import cv2
    except ImportError as exc:
        raise SystemExit("opencv-python is not installed. Install requirements-ai.txt first.") from exc
    return cv2


def _face_recognition():
    try:
        import face_recognition
    except ImportError as exc:
        raise SystemExit("face-recognition is not installed. Install requirements-ai.txt first.") from exc
    return face_recognition


if __name__ == "__main__":
    main()
