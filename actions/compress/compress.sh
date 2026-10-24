#!/usr/bin/env bash
# Usage: compress.sh <path> <gz|zst|xz>
set -euo pipefail
path="${1%/}"
fmt="${2:-gz}"
case "$fmt" in
  gz)  flag=z ;;
  xz)  flag=J ;;
  zst) flag="--zstd" ;;
  *)   notify-send "Compress" "Unknown format: $fmt"; exit 1 ;;
esac
out="$path.tar.$fmt"
if [[ "$flag" == "--zstd" ]]; then
  tar --zstd -cf "$out" -C "$(dirname "$path")" "$(basename "$path")"
else
  tar -c"$flag"f "$out" -C "$(dirname "$path")" "$(basename "$path")"
fi
notify-send "Compress" "Created $out"
