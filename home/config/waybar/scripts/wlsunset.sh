#!/usr/bin/env bash
if [ "$1" = "toggle" ]; then
    if pgrep -x "wlsunset" > /dev/null; then
        pkill -x "wlsunset"
    else
        wlsunset -l 45.5 -L -73.6 -t 2700 -T 6500 &
    fi
elif [ "$1" = "status" ]; then
    if pgrep -x "wlsunset" > /dev/null; then
        echo '{"text": "", "class": "on", "tooltip": "Blue Light Filter: Active (4000K)"}'
    else
        echo '{"text": "", "class": "off", "tooltip": "Blue Light Filter: Inactive"}'
    fi
fi
