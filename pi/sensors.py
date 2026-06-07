import grovepi
import paho.mqtt.client as mqtt
import json
import time
from datetime import datetime, timezone

BROKER = "10.0.0.1"
LIGHT_PIN = 0   # A0
DHT_PIN = 3     # D3
DHT_TYPE = 0    # 0 = DHT11, 1 = DHT22
PIR_PIN = 2     # D2 (not wired yet)
INTERVAL = 30   # seconds between DHT/light readings

client = mqtt.Client()
client.reconnect_delay_set(min_delay=1, max_delay=30)
client.connect(BROKER, 1883)
client.loop_start()

prev_motion = 0
print("Sensors running...")

while True:
    now = datetime.now(timezone.utc).isoformat()

    try:
        # PIR motion — publish only on rising edge (0 -> 1)
        # Uncomment when PIR is wired to D2
        # motion = grovepi.digitalRead(PIR_PIN)
        # if motion == 1 and prev_motion == 0:
        #     client.publish("security/sensors/motion", json.dumps({
        #         "triggered": True,
        #         "timestamp": now
        #     }))
        #     print("Motion detected")
        # prev_motion = motion

        # light sensor (raw ADC 0-1023)
        light = grovepi.analogRead(LIGHT_PIN)
        client.publish("security/sensors/light", json.dumps({
            "value": light,
            "timestamp": now
        }))

        # temp + humidity
        [temp, humidity] = grovepi.dht(DHT_PIN, DHT_TYPE)
        if temp == temp and humidity == humidity:  # NaN check
            client.publish("security/sensors/dht", json.dumps({
                "temperature_c": round(temp, 1),
                "humidity_percent": round(humidity, 1),
                "timestamp": now
            }))

        print(f"Temp: {temp}°C | Humidity: {humidity}% | Light: {light}")

    except Exception as e:
        print(f"Sensor error: {e}")

    time.sleep(INTERVAL)
