import grovepi
import time

PORT = 4

print("Setting pin mode...")
grovepi.pinMode(PORT, "INPUT")
time.sleep(1)

print("Reading PIR sensor values...")

while True:
    try:
        print("Before digitalRead")
        value = grovepi.digitalRead(PORT)
        print("After digitalRead:", value)
        time.sleep(0.5)

    except Exception as e:
        print("ERROR:", repr(e))
        time.sleep(1)