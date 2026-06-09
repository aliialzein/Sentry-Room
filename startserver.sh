#!/usr/bin/env bash
set -euo pipefail

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8000}"
APP="${APP:-app.main:app}"

cd "$(dirname "$0")"

find_port_pids() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -ti "tcp:${PORT}" || true
    return
  fi

  if command -v fuser >/dev/null 2>&1; then
    fuser "${PORT}/tcp" 2>/dev/null || true
    return
  fi

  if command -v ss >/dev/null 2>&1; then
    ss -ltnp "sport = :${PORT}" 2>/dev/null | sed -n 's/.*pid=\([0-9][0-9]*\).*/\1/p' | sort -u || true
    return
  fi

  echo "lsof, fuser, and ss are unavailable; cannot find process on port ${PORT}." >&2
  return 1
}

PIDS="$(find_port_pids | xargs || true)"

if [ -n "${PIDS}" ]; then
  echo "Stopping process(es) on port ${PORT}: ${PIDS}"
  kill ${PIDS} 2>/dev/null || true
  sleep 2

  REMAINING="$(find_port_pids | xargs || true)"
  if [ -n "${REMAINING}" ]; then
    echo "Force stopping process(es) on port ${PORT}: ${REMAINING}"
    kill -9 ${REMAINING} 2>/dev/null || true
  fi
else
  echo "No process is listening on port ${PORT}."
fi

echo "Starting ${APP} on ${HOST}:${PORT}"
exec env PYTHONFAULTHANDLER=1 python3 -X faulthandler -m uvicorn "${APP}" --host "${HOST}" --port "${PORT}"
