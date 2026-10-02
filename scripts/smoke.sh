#!/usr/bin/env bash
# Smoke test: start `middleman serve`, check every top-level page returns 200, stop the server.
# Usage (from the repo root): bash scripts/smoke.sh
set -u
PORT=${PORT:-4567}
LOG=${TMPDIR:-/tmp}/middleman-smoke.log
bundle exec middleman serve --port "$PORT" > "$LOG" 2>&1 &
PID=$!
trap 'kill $PID 2>/dev/null; wait $PID 2>/dev/null' EXIT
for _ in $(seq 1 60); do
  curl -s -o /dev/null "http://localhost:$PORT/" && break
  sleep 1
done
FAIL=0
for page in / $(cd source && ls *.html.slim | sed 's/\.slim$//; s|^|/|'); do
  code=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:$PORT$page")
  echo "$code $page"
  [ "$code" = 200 ] || FAIL=1
done
if grep -iE 'warn|error|exception' "$LOG"; then FAIL=1; fi
[ $FAIL = 0 ] && echo "SMOKE OK" || { echo "SMOKE FAILED (log: $LOG)"; exit 1; }
