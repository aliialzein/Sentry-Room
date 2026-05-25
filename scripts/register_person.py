from pathlib import Path
import argparse
import sys


sys.path.append(str(Path(__file__).resolve().parents[1]))

from app.core.database import SessionLocal
from app.iot.camera import find_camera
from app.models.person import Person
from app.services.recognition import FaceRecognitionService
from app.services.storage import save_bytes_file


def main() -> None:
    parser = argparse.ArgumentParser(description="Register a person from the local camera.")
    parser.add_argument("name", help="Person full name")
    parser.add_argument("--role", default=None, help="Optional role, such as staff or admin")
    args = parser.parse_args()

    cv2 = _cv2()
    capture = find_camera()
    if capture is None:
        raise SystemExit("No camera found.")

    image_bytes = None
    print("Look at the camera. Press SPACE to capture, Q to quit.")

    try:
        while True:
            success, frame = capture.read()
            if not success:
                break
            cv2.putText(frame, "Press SPACE to capture", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 255), 2)
            cv2.imshow("Sentry Room Enrollment", frame)
            key = cv2.waitKey(1) & 0xFF
            if key == ord("q"):
                break
            if key == ord(" "):
                encoded, buffer = cv2.imencode(".jpg", frame)
                if encoded:
                    image_bytes = buffer.tobytes()
                    break
    finally:
        capture.release()
        cv2.destroyAllWindows()

    if image_bytes is None:
        raise SystemExit("Registration cancelled.")

    recognizer = FaceRecognitionService()
    encoding = recognizer.encoding_from_image(image_bytes)
    image_path = save_bytes_file(image_bytes, subdir="enrollments", filename_prefix=args.name.replace(" ", "_").lower())

    db = SessionLocal()
    try:
        person = Person(full_name=args.name, role=args.role, is_authorized=True, face_encoding=encoding, image_path=image_path)
        db.add(person)
        db.commit()
        db.refresh(person)
    finally:
        db.close()

    print(f"Registered {args.name} with id {person.id}.")


def _cv2():
    try:
        import cv2
    except ImportError as exc:
        raise SystemExit("opencv-python is not installed. Install requirements before camera enrollment.") from exc
    return cv2


if __name__ == "__main__":
    main()
