from collections.abc import Iterator

from fastapi import APIRouter, HTTPException, Response, status
from fastapi.responses import StreamingResponse

from app.iot.camera import find_camera, jpeg_frames


router = APIRouter()


@router.get("/snapshot")
def camera_snapshot() -> Response:
    capture = find_camera()
    if capture is None:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="No camera found")

    try:
        frame = next(jpeg_frames(capture), None)
    finally:
        capture.release()

    if frame is None:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Could not capture frame")

    return Response(content=frame, media_type="image/jpeg")


@router.get("/stream")
def camera_stream() -> StreamingResponse:
    capture = find_camera()
    if capture is None:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="No camera found")

    return StreamingResponse(
        _mjpeg_stream(capture),
        media_type="multipart/x-mixed-replace; boundary=frame",
    )


def _mjpeg_stream(capture) -> Iterator[bytes]:
    try:
        for frame in jpeg_frames(capture):
            yield b"--frame\r\nContent-Type: image/jpeg\r\n\r\n" + frame + b"\r\n"
    finally:
        capture.release()
