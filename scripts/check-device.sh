#!/bin/bash
set -uo pipefail

SDK=/root/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.1.0-2026-03-09-6a872a80b/bin
PROJECT=/workspace/no-track-run-watch
JUNGLE=$PROJECT/monkey.jungle
MANIFEST=$PROJECT/manifest.xml
KEY=/workspace/developer_key
DEVICES_DIR=/root/.Garmin/ConnectIQ/Devices
OUT=/tmp/garmin
JOBS=${JOBS:-3}            # chaque JVM consomme de la RAM, ne monte pas trop
TYPECHECK=${TYPECHECK:-1}  # 0 à 3
SCRIPT_START=$SECONDS

rm -rf "$OUT"; mkdir -p "$OUT"

build_one() {
  local device=$1 mode=$2
  local flags=(-w -l "$TYPECHECK")
  [ "$mode" = release ] && flags+=(-r)
  local prg="$OUT/$device-$mode.prg" log="$OUT/$device-$mode.log"

  printf '▶ %-26s %-8s en cours...\n' "$device" "$mode"
  local start=$SECONDS

  java -Xms512m -Dfile.encoding=UTF-8 -jar "$SDK/monkeybrains.jar" \
       -o "$prg" -f "$JUNGLE" -y "$KEY" -d "$device" "${flags[@]}" > "$log" 2>&1
  local rc=$?

  local warns size=0 mem
  warns=$(grep -c 'WARNING' "$log")   # adapte le motif si ton SDK formate autrement
  [ -f "$prg" ] && size=$(stat -c %s "$prg")
  mem=$(python3 - "$DEVICES_DIR/$device/compiler.json" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    print(next((t.get("memoryLimit", "N/A") for t in d.get("appTypes", [])
                if t.get("type") == "watchApp"), "N/A"))
except Exception:
    print("N/A")
PY
)
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$([ $rc -eq 0 ] && echo OK || echo FAIL)" "$device" "$mode" "$warns" "$size" "$mem" \
    > "$OUT/$device-$mode.res"

  # Le .res est écrit avant le compteur : nombre de .res = builds terminés
  local done_count
  done_count=$(ls "$OUT"/*.res 2>/dev/null | wc -l)
  printf '%s [%d/%d] %-26s %-8s %3ds  warn=%s\n' \
    "$([ $rc -eq 0 ] && echo ✅ || echo ❌)" "$done_count" "$TOTAL" \
    "$device" "$mode" "$(( SECONDS - start ))" "$warns"
  [ $rc -ne 0 ] && echo "   └─ $(grep -m1 -i 'error' "$log")"
  return 0
}
export -f build_one
export SDK JUNGLE KEY DEVICES_DIR OUT TYPECHECK

mapfile -t DEVICES < <(grep -oP '(?<=<iq:product id=")[^"]+' "$MANIFEST")
TOTAL=$(( ${#DEVICES[@]} * 2 ))
export TOTAL
echo "Compilation de ${#DEVICES[@]} appareils x 2 modes = $TOTAL builds ($JOBS en parallèle)"
echo

for d in "${DEVICES[@]}"; do
  for m in debug release; do echo "$d $m"; done
done | xargs -P "$JOBS" -L1 bash -c 'build_one "$0" "$1"'

{
  printf 'STATUS\tDEVICE\tMODE\tWARN\tPRG_BYTES\tMEM_LIMIT\n'
  cat "$OUT"/*.res | sort -k2,3
} > "$OUT/tests.tsv"

echo
echo "=== Résultats ==="
awk -F'\t' '{ printf "%-6s %-26s %-8s %-5s %-10s %s\n", $1, $2, $3, $4, $5, $6 }' "$OUT/tests.tsv"
mkdir -p /workspace/scripts
cp "$OUT/tests.tsv" /workspace/scripts/

echo; echo "=== Échecs ==="
FAILS=$(grep -c '^FAIL' "$OUT/tests.tsv")
grep '^FAIL' "$OUT/tests.tsv" | while IFS=$'\t' read -r _ dev mode _; do
  echo "$dev ($mode): $(grep -m1 -i 'error' "$OUT/$dev-$mode.log")"
done

echo; echo "Terminé en $(( SECONDS - SCRIPT_START ))s, $FAILS échec(s)"
exit $(( FAILS > 0 ))
