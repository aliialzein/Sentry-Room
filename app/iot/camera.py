from collections.abc import Iterator
import os


def find_camera(max_index: int = 5):
    cv2 = _cv2()
    backend = cv2.CAP_DSHOW if os.name == "nt" else None

    for index in range(max_index):
        capture = cv2.VideoCapture(index, backend) if backend is not None else cv2.VideoCapture(index)
        if capture.isOpened():
            success, _ = capture.read()
            if success:
                return capture
            capture.release()
    return None


def jpeg_frames(capture) -> Iterator[bytes]:
    cv2 = _cv2()
    while True:
        success, frame = capture.read()
        if not success:
            break
        encoded, buffer = cv2.imencode(".jpg", frame)
        if encoded:
            yield buffer.tobytes()


def _cv2():
    try:
        import cv2
    except ImportError as exc:
        raise RuntimeError("opencv-python is not installed. Install requirements before using the camera.") from exc
    return cv2
