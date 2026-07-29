#!/bin/bash

SDK=/root/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.1.0-2026-03-09-6a872a80b/bin
JUNGLE=/workspace/no-track-run-watch/monkey.jungle
KEY=/workspace/developer_key
OUT=/tmp/garmin
MANIFEST=/workspace/no-track-run-watch/manifest.xml

mkdir -p $OUT

DEVICES=($(grep -oP '(?<=<iq:product id=")[^"]+' $MANIFEST))

RESULTS="$OUT/tests.txt" > "$RESULTS"

for DEVICE in "${DEVICES[@]}"; do
  LOG="$OUT/$DEVICE.log"
  java -Xms1g -Dfile.encoding=UTF-8 -jar "$SDK/monkeybrains.jar" \
       -o "$OUT/$DEVICE.prg" -f "$JUNGLE" -y "$KEY" -d "$DEVICE" -w \
       > "$LOG" 2>&1

  if grep -qi "does not support\|ERROR" "$LOG"; then
    echo "❌ $DEVICE  -> $(grep -i 'does not support\|ERROR' "$LOG" | head -1)" | tee -a "$RESULTS"
  else
    echo "✅ $DEVICE" | tee -a "$RESULTS"
  fi
done

echo ""
echo "=== Résumé ==="
grep "❌" "$RESULTS"

cp $RESULTS /workspace/scripts