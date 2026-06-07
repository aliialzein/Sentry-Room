import asyncio
import json
import logging
import shutil
import threading
from datetime import datetime, timezone
from pathlib import Path

import paho.mqtt.client as mqtt

from app.core.config import get_settings
from app.core.database import SessionLocal
from app.models.enums import EventSeverity, EventType, SensorType
from app.models.event import AccessEvent
from app.models.sensor import SensorReading
from app.services.websocket_manager import manager

logger = logging.getLogger(__name__)

_loop: asyncio.AbstractEventLoop | None = None
_client: mqtt.Client | None = None

SUBSCRIBED_TOPICS = [
    "security/sensors/dht",
    "security/sensors/light",
    "security/sensors/motion",
    "security/camera/event",
    "security/alerts",
    "security/alerts/description",
]


def _broadcast(payload: dict) -> None:
    if _loop is None:
        return
    asyncio.run_coroutine_threadsafe(manager.broadcast(payload), _loop)


# ---------- handlers ----------

def _handle_dht(payload: dict) -> None:
    temperature = _number(payload, "temperature_c", "temp", "temperature")
    humidity = _number(payload, "humidity_percent", "humidity")
    if temperature is None and humidity is None:
        logger.warning("Ignoring DHT payload without temperature/humidity: %s", payload)
        return

    value = {}
    if temperature is not None:
        value["temperature_c"] = temperature
    if humidity is not None:
        value["humidity_percent"] = humidity

    _store_sensor_reading(
        sensor_type=SensorType.TEMPERATURE_HUMIDITY,
        value=value,
        unit="C / %",
        source="pi_dht11",
    )


def _handle_light(payload: dict) -> None:
    light_value = _number(payload, "value", "light", "raw_adc")
    if light_value is None:
        logger.warning("Ignoring light payload without value: %s", payload)
        return

    _store_sensor_reading(
        sensor_type=SensorType.LIGHT,
        value={"value": light_value},
        unit="raw_adc",
        source="pi_light",
    )


def _handle_motion(payload: dict) -> None:
    _store_sensor_reading(
        sensor_type=SensorType.MOTION,
        value={"triggered": bool(payload.get("triggered", True))},
        source="pi_pir",
    )


def _handle_camera_event(payload: dict) -> None:
    names = payload.get("names", [])
    db = SessionLocal()
    try:
        event = AccessEvent(
            event_type=EventType.AUTHORIZED_ENTRY,
            severity=EventSeverity.INFO,
            message=f"Recognized: {', '.join(names)}",
        )
        db.add(event)
        db.commit()
        db.refresh(event)
        _broadcast({
            "type": "authorized_entry",
            "event_id": event.id,
            "names": names,
            "timestamp": event.created_at.isoformat(),
        })
    finally:
        db.close()


def _handle_alert(payload: dict) -> None:
    settings = get_settings()
    snapshot_src = payload.get("snapshot")
    evidence_path: str | None = None

    if snapshot_src:
        src = Path(snapshot_src)
        if src.exists():
            dest = settings.evidence_dir / src.name
            shutil.copy2(src, dest)
            evidence_path = str(dest)
        else:
            logger.warning("Snapshot not found: %s", snapshot_src)

    db = SessionLocal()
    try:
        event = AccessEvent(
            event_type=EventType.UNAUTHORIZED_ENTRY,
            severity=EventSeverity.CRITICAL,
            message=f"Unknown person detected ({payload.get('person_count', 1)} person(s))",
            snapshot_path=evidence_path,
            sensor_payload={"armed": payload.get("armed", False)},
        )
        db.add(event)
        db.commit()
        db.refresh(event)
        _broadcast({
            "type": "unauthorized_entry",
            "event_id": event.id,
            "snapshot": evidence_path,
            "armed": payload.get("armed", False),
            "timestamp": event.created_at.isoformat(),
        })
    finally:
        db.close()


def _handle_description(payload: dict) -> None:
    settings = get_settings()
    snapshot_src = payload.get("snapshot")
    description = payload.get("description", "").strip()

    if not snapshot_src or not description:
        return

    evidence_path = str(settings.evidence_dir / Path(snapshot_src).name)

    db = SessionLocal()
    try:
        event = (
            db.query(AccessEvent)
            .filter(AccessEvent.snapshot_path == evidence_path)
            .order_by(AccessEvent.created_at.desc())
            .first()
        )
        if not event:
            logger.warning("No event found for snapshot %s", evidence_path)
            return
        event.message = description
        db.commit()
        _broadcast({
            "type": "alert_description",
            "event_id": event.id,
            "description": description,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        })
    finally:
        db.close()


# ---------- paho callbacks ----------

def _on_connect(client, userdata, flags, rc):
    if rc == 0:
        logger.info("MQTT bridge connected to broker")
        for topic in SUBSCRIBED_TOPICS:
            client.subscribe(topic)
    else:
        logger.error("MQTT broker connection refused (rc=%d)", rc)


def _on_message(client, userdata, msg):
    try:
        payload = json.loads(msg.payload)
    except json.JSONDecodeError:
        logger.warning("Non-JSON message on %s", msg.topic)
        return

    dispatch = {
        "security/sensors/dht": _handle_dht,
        "security/sensors/light": _handle_light,
        "security/sensors/motion": _handle_motion,
        "security/camera/event": _handle_camera_event,
        "security/alerts": _handle_alert,
        "security/alerts/description": _handle_description,
    }

    handler = dispatch.get(msg.topic)
    if handler:
        try:
            handler(payload)
        except Exception:
            logger.exception("Error in handler for %s", msg.topic)


def _number(payload: dict, *keys: str) -> float | None:
    for key in keys:
        raw_value = payload.get(key)
        if raw_value is None:
            continue
        try:
            return float(raw_value)
        except (TypeError, ValueError):
            logger.warning("Invalid numeric MQTT value for %s: %r", key, raw_value)
    return None


def _store_sensor_reading(
    sensor_type: SensorType,
    value: dict,
    source: str,
    unit: str | None = None,
) -> None:
    db = SessionLocal()
    try:
        reading = SensorReading(
            sensor_type=sensor_type,
            value=value,
            unit=unit,
            source=source,
        )
        db.add(reading)
        db.commit()
        db.refresh(reading)
        _broadcast({
            "type": "sensor_reading",
            "sensor_type": sensor_type.value,
            "value": value,
            "source": source,
            "timestamp": reading.created_at.isoformat(),
        })
    finally:
        db.close()


# ---------- public API ----------

def publish(topic: str, payload: dict) -> None:
    """Publish a message. Used by routes (e.g. settings arm/disarm)."""
    if _client is None:
        logger.warning("MQTT client not ready — cannot publish to %s", topic)
        return
    _client.publish(topic, json.dumps(payload))


def start(loop: asyncio.AbstractEventLoop) -> None:
    global _loop, _client

    _loop = loop
    settings = get_settings()
    client = mqtt.Client()
    client.on_connect = _on_connect
    client.on_message = _on_message
    client.reconnect_delay_set(min_delay=1, max_delay=30)

    try:
        client.connect(settings.mqtt_host, settings.mqtt_port)
    except Exception:
        logger.exception("Cannot reach MQTT broker — bridge disabled")
        return

    _client = client
    threading.Thread(target=client.loop_forever, daemon=True, name="mqtt-bridge").start()
    logger.info("MQTT bridge started")
