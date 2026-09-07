#!/usr/bin/env bash

# Resolve target path from argument (passed by Thunar as %f)
target="${1:-}"

# Remove file:// prefix if present
target="${target#file://}"

# Decode percent-encoded characters (e.g. %20 -> space) if present
if [[ "$target" == *"%"* ]]; then
    target="$(printf '%b' "${target//%/\\x}")"
fi

# If target is empty, use current working directory or HOME
if [ -z "$target" ]; then
    target="$PWD"
fi

# Determine directory to open
if [ -d "$target" ]; then
    working_dir="$target"
elif [ -f "$target" ] || [ -e "$target" ]; then
    working_dir="$(dirname "$target")"
else
    working_dir="$HOME"
fi

# Final fallback check
if [ ! -d "$working_dir" ]; then
    working_dir="$HOME"
fi

exec kitty --directory "$working_dir"
