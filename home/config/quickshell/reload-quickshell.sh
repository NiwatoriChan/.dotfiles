#!/usr/bin/env bash
# Reload QuickShell

echo "Stopping QuickShell..."
quickshell kill 2>/dev/null || true
pkill -9 -x .quickshell-wra 2>/dev/null || true
pkill -9 -x quickshell 2>/dev/null || true
sleep 0.5

# Start new instance with duplicate protection
echo "Starting QuickShell..."
quickshell -n -d

echo "Done."

