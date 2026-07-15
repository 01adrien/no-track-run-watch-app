#!/bin/bash

SDK=/root/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.1.0-2026-03-09-6a872a80b/bin
JUNGLE=/workspace/no-track-run-watch/monkey.jungle
KEY=/workspace/developer_key
OUT=/tmp/build_check

mkdir -p $OUT

DEVICES=(
  fr245 fr245m fr255 fr255s fr255sm fr255m fr265 fr265s
  fr745 fr945 fr945lte fr955 fr965 fr970
 fenix5plus fenix5splus fenix5xplus
  fenix6 fenix6pro fenix6s fenix6spro fenix6xpro
  fenix7 fenix7pro fenix7pronowifi fenix7s fenix7spro fenix7x fenix7xpro fenix7xpronowifi
  fenix843mm fenix847mm fenix8pro47mm fenix8solar47mm fenix8solar51mm fenixe
  epix2 epix2pro42mm epix2pro47mm epix2pro51mm
  instinct3amoled45mm instinct3amoled50mm instinct3solar45mm
  instinctcrossoveramoled
  enduro enduro3
  marq2 marq2aviator marqadventurer marqathlete marqaviator
  marqcaptain marqcommander marqdriver marqexpedition marqgolfer
  d2airx10  d2bravo_titanium  d2mach1 d2mach2
)

RESULTS="$OUT/results.txt"
> "$RESULTS"

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

