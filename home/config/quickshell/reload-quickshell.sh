#!/bin/bash
# Reload QuickShell

# Kill existing instance gracefully first, then force if needed
if pgrep -f quickshell > /dev/null; then
    echo "Stopping QuickShell..."
    pkill -f quickshell
    # Wait up to 5 seconds
    for i in {1..50}; do
        if ! pgrep -f quickshell > /dev/null; then
            break
        fi
        sleep 0.1
    done
    # Force kill if still running
    if pgrep -f quickshell > /dev/null; then
        pkill -9 -f quickshell
    fi
fi

# Start new instance
echo "Starting QuickShell..."
nohup quickshell > /dev/null 2>&1 &

echo "Done."
