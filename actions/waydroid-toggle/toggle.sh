#!/usr/bin/env bash
set -e

if waydroid status 2>&1 | grep -q "RUNNING"; then
    waydroid session stop
else
    waydroid show-full-ui &
fi
