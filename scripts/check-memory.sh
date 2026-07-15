#!/bin/bash

DEVICES_DIR=/root/.Garmin/ConnectIQ/Devices
RESULTS=/workspace/scripts/results.txt

for DEVICE in $(grep -oP '(?<=✅ )\S+' "$RESULTS"); do
  JSON="$DEVICES_DIR/$DEVICE/compiler.json"
  if [ -f "$JSON" ]; then
    MEM=$(python3 -c "
import json
with open('$JSON') as f:
    data = json.load(f)
for t in data.get('appTypes', []):
    if t.get('type') == 'watchApp':
        print(t.get('memoryLimit', 'N/A'))
        break
")
    echo "$DEVICE : ${MEM} bytes"
  else
    echo "$DEVICE : compiler.json introuvable"
  fi
done | sort -t: -k2 -n