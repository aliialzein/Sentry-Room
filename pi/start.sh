#!/bin/bash

DIR="$(cd "$(dirname "$0")" && pwd)"

# WireGuard
echo "==> Starting WireGuard..."
sudo wg-quick up wg0 2>/dev/null && echo "VPN up" || echo "VPN already running"

# Wait until server is reachable over VPN
echo "==> Waiting for server (10.0.0.1)..."
until ping -c 1 -W 1 10.0.0.1 &>/dev/null; do
    sleep 1
done
echo "Server reachable"

# Sensors in background
echo "==> Starting sensors..."
python3 "$DIR/sensors.py" &
SENSOR_PID=$!

# Kill sensor process on exit
cleanup() {
    echo "Stopping..."
    kill "$SENSOR_PID" 2>/dev/null
    exit 0
}
trap cleanup SIGINT SIGTERM

# Camera stream — loops on disconnect so it reconnects if server restarts
echo "==> Starting camera stream to 10.0.0.1:9000..."
while true; do
    v4l2-ctl --device=/dev/video0 \
        --set-fmt-video=width=640,height=480,pixelformat=MJPG \
        --set-parm=10 \
        --stream-mmap --stream-count=0 --stream-to=- | nc 10.0.0.1 9000
    echo "Stream disconnected, retrying in 5s..."
    sleep 5
done
