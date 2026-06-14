import argparse
import json
from datetime import datetime, timezone

import paho.mqtt.client as mqtt


def main():
    parser = argparse.ArgumentParser(description="Publish a Sentry Room fire-risk demo trigger.")
    parser.add_argument("--broker", default="10.0.0.1")
    parser.add_argument("--port", type=int, default=1883)
    parser.add_argument("--temperature", type=float, default=39.5)
    parser.add_argument("--humidity", type=float, default=34.0)
    parser.add_argument("--light", type=float, default=860.0)
    parser.add_argument("--reason", default="pi_manual_fire_test")
    args = parser.parse_args()

    payload = {
        "temperature_c": args.temperature,
        "humidity_percent": args.humidity,
        "light_value": args.light,
        "trigger_reason": args.reason,
        "source": "pi_fire_risk_trigger",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    client = mqtt.Client()
    client.connect(args.broker, args.port, keepalive=30)
    client.publish("security/sensors/fire-risk", json.dumps(payload), qos=1)
    client.disconnect()

    print("Published fire-risk trigger:")
    print(json.dumps(payload, indent=2))


if __name__ == "__main__":
    main()
