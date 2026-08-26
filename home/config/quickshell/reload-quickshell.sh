#!/usr/bin/env bash
# Reload QuickShell

echo "Stopping QuickShell..."
quickshell kill 2>/dev/null || true
sleep 0.3

# Start new instance
echo "Starting QuickShell..."
quickshell -d

echo "Done."

