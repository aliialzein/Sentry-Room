from enum import Enum


class EventType(str, Enum):
    AUTHORIZED_ENTRY = "authorized_entry"
    UNAUTHORIZED_ENTRY = "unauthorized_entry"
    MOTION_DETECTED = "motion_detected"
    ENVIRONMENTAL_ALERT = "environmental_alert"
    SENSOR_FAULT = "sensor_fault"
    SYSTEM_EVENT = "system_event"


class EventSeverity(str, Enum):
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"


class SensorType(str, Enum):
    CAMERA = "camera"
    MOTION = "motion"
    TEMPERATURE_HUMIDITY = "temperature_humidity"
    DISTANCE = "distance"


class AlertChannel(str, Enum):
    EMAIL = "email"
    APP = "app"


class DeliveryStatus(str, Enum):
    PENDING = "pending"
    SENT = "sent"
    FAILED = "failed"
