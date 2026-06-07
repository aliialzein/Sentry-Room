from collections.abc import Iterator
import logging
import socket
import threading
import time

from app.core.config import get_settings


logger = logging.getLogger(__name__)


class PiCameraStream:
    def __init__(self) -> None:
        self._latest_frame: bytes | None = None
        self._frame_condition = threading.Condition()
        self._stop_event = threading.Event()
        self._thread: threading.Thread | None = None
        self._server_socket: socket.socket | None = None

    def start(self) -> None:
        settings = get_settings()
        if not settings.pi_camera_enabled:
            logger.info("Pi camera receiver disabled")
            return
        if self._thread and self._thread.is_alive():
            return

        self._stop_event.clear()
        self._thread = threading.Thread(
            target=self._run_receiver,
            name="pi-camera-receiver",
            daemon=True,
        )
        self._thread.start()

    def stop(self) -> None:
        self._stop_event.set()
        if self._server_socket is not None:
            try:
                self._server_socket.close()
            except OSError:
                pass

    def latest_frame(self) -> bytes | None:
        with self._frame_condition:
            return self._latest_frame

    def wait_for_frame(self, timeout: float = 5.0) -> bytes | None:
        end_at = time.monotonic() + timeout
        with self._frame_condition:
            while self._latest_frame is None:
                remaining = end_at - time.monotonic()
                if remaining <= 0:
                    return None
                self._frame_condition.wait(timeout=remaining)
            return self._latest_frame

    def mjpeg_frames(self) -> Iterator[bytes]:
        last_frame: bytes | None = None
        while not self._stop_event.is_set():
            with self._frame_condition:
                self._frame_condition.wait(timeout=1.0)
                frame = self._latest_frame

            if frame is None or frame == last_frame:
                continue

            last_frame = frame
            yield b"--frame\r\nContent-Type: image/jpeg\r\n\r\n" + frame + b"\r\n"

    def _run_receiver(self) -> None:
        settings = get_settings()
        host = settings.pi_camera_tcp_host
        port = settings.pi_camera_tcp_port

        try:
            server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            server_socket.bind((host, port))
            server_socket.listen(1)
            server_socket.settimeout(1.0)
            self._server_socket = server_socket
        except OSError:
            logger.exception("Could not start Pi camera receiver on %s:%s", host, port)
            return

        logger.info("Pi camera receiver listening on %s:%s", host, port)
        try:
            while not self._stop_event.is_set():
                try:
                    connection, address = server_socket.accept()
                except socket.timeout:
                    continue
                except OSError:
                    break

                logger.info("Pi camera connected from %s", address)
                with connection:
                    connection.settimeout(2.0)
                    self._receive_frames(connection)
                logger.info("Pi camera disconnected")
        finally:
            try:
                server_socket.close()
            except OSError:
                pass

    def _receive_frames(self, connection: socket.socket) -> None:
        buffer = b""
        while not self._stop_event.is_set():
            try:
                chunk = connection.recv(131072)
            except socket.timeout:
                continue
            except OSError:
                break

            if not chunk:
                break

            buffer += chunk
            frame, buffer = self._extract_latest_jpeg(buffer)
            if frame is not None:
                with self._frame_condition:
                    self._latest_frame = frame
                    self._frame_condition.notify_all()

            if len(buffer) > 2_000_000:
                buffer = buffer[-200_000:]

    @staticmethod
    def _extract_latest_jpeg(buffer: bytes) -> tuple[bytes | None, bytes]:
        last_start = -1
        last_end = -1
        position = 0

        while True:
            start = buffer.find(b"\xff\xd8", position)
            end = buffer.find(b"\xff\xd9", start if start != -1 else position)
            if start != -1 and end != -1 and end > start:
                last_start = start
                last_end = end
                position = end + 2
                continue
            break

        if last_start == -1 or last_end == -1:
            return None, buffer

        frame = buffer[last_start : last_end + 2]
        remaining = buffer[last_end + 2 :]
        return frame, remaining


pi_camera_stream = PiCameraStream()
