#!/usr/bin/env bash
# Generate AppIcon.icns from Resources/icon_1024.png
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/Resources/icon_1024.png"
ISET="$ROOT/build/AppIcon.iconset"
OUT="$ROOT/Resources/AppIcon.icns"

test -f "$SRC" || { echo "missing $SRC; run scripts/generate_icon.py first" >&2; exit 1; }

rm -rf "$ISET"
mkdir -p "$ISET"

declare -a sizes=(16 32 64 128 256 512 1024)
for s in "${sizes[@]}"; do
  sips -z "$s" "$s" "$SRC" --out "$ISET/icon_${s}x${s}.png" >/dev/null
  s2=$((s * 2))
  if [[ $s -lt 1024 ]]; then
    sips -z "$s2" "$s2" "$SRC" --out "$ISET/icon_${s}x${s}@2x.png" >/dev/null
  fi
done

iconutil -c icns "$ISET" -o "$OUT"
echo "wrote $OUT"
