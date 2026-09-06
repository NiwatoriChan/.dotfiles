#!/usr/bin/env bash
# ==============================================================================
# PwPoulet Display Switcher
# Switch main display (DP-1) between 1080p 60Hz and 2K 144Hz
# Exclusively intended for PwPoulet
# ==============================================================================
set -euo pipefail

# --- Host Validation ---
CURRENT_HOST=$(cat /etc/hostname 2>/dev/null || hostname 2>/dev/null || echo "")
if [ "$CURRENT_HOST" != "PwPoulet" ] && [ "$CURRENT_HOST" != "pwpoulet" ]; then
    echo "Error: This display switcher is configured exclusively for PwPoulet (DP-1)." >&2
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u critical -a "Display Switcher" "Display Switcher" "This shortcut is only available on PwPoulet." 2>/dev/null || true
    fi
    exit 1
fi

OUTPUT="DP-1"
POS_X="0"
POS_Y="1080"
SCALE="1"
VRR="1"

get_current_mode() {
    local res=""
    if command -v hyprctl >/dev/null 2>&1; then
        res=$(hyprctl monitors -j 2>/dev/null | jq -r --arg out "$OUTPUT" '.[] | select(.name == $out) | "\(.width)x\(.height)@\(.refreshRate | round)"' 2>/dev/null || true)
        if [ -n "$res" ] && [ "$res" != "null" ]; then
            echo "$res"
            return 0
        fi
    fi

    if command -v wlr-randr >/dev/null 2>&1; then
        res=$(wlr-randr --json 2>/dev/null | jq -r --arg out "$OUTPUT" '.[] | select(.name == $out) | .modes[] | select(.current == true) | "\(.width)x\(.height)@\(.refresh | round)"' 2>/dev/null || true)
        if [ -n "$res" ] && [ "$res" != "null" ]; then
            echo "$res"
            return 0
        fi
    fi

    echo "unknown"
}

apply_mode() {
    local target="$1"
    local mode_str=""
    local label=""

    case "$target" in
        1080p|1080|60|fhd|FHD)
            mode_str="1920x1080@60"
            label="1080p 60Hz"
            ;;
        2k|2K|1440p|1440|144|qhd|QHD)
            mode_str="2560x1440@144"
            label="2K 144Hz"
            ;;
        *)
            echo "Error: Unsupported target mode '$target'. Supported modes: 1080p, 2k" >&2
            return 1
            ;;
    esac

    echo "Switching $OUTPUT to $label ($mode_str)..."

    # 1. Apply via wlr-randr if available
    if command -v wlr-randr >/dev/null 2>&1; then
        wlr-randr --output "$OUTPUT" --mode "${mode_str}Hz" --pos "${POS_X},${POS_Y}" --scale "$SCALE" --adaptive-sync enabled 2>/dev/null || \
        wlr-randr --output "$OUTPUT" --mode "$mode_str" --pos "${POS_X},${POS_Y}" --scale "$SCALE" --adaptive-sync enabled 2>/dev/null || true
    fi

    # 2. Update Hyprland Lua state if running under Hyprland
    if [ "${XDG_CURRENT_DESKTOP:-}" = "Hyprland" ] || command -v hyprctl >/dev/null 2>&1; then
        hyprctl eval "hl.monitor({ output = '${OUTPUT}', mode = '${mode_str}', position = '${POS_X}x${POS_Y}', scale = ${SCALE}, vrr = ${VRR} })" >/dev/null 2>&1 || true
    fi

    # 3. Apply via kscreen-doctor if running under KDE Plasma
    if command -v kscreen-doctor >/dev/null 2>&1; then
        kscreen-doctor "output.${OUTPUT}.mode.${mode_str}" >/dev/null 2>&1 || true
    fi

    # 4. Notify user
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl notify 1 3000 0 "Display: Switched to $label" >/dev/null 2>&1 || true
    fi
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Display Switcher" -i video-display "Display Resolution" "Main display ($OUTPUT) set to $label" 2>/dev/null || true
    fi

    # 5. Restore wallpaper geometry if wallpaper-picker is available
    local wp_script="${HOME}/.dotfiles/home/config/scripts/wallpaper-picker.sh"
    if [ -x "$wp_script" ]; then
        "$wp_script" --restore >/dev/null 2>&1 &
    fi

    echo "Successfully switched $OUTPUT to $label."
}

toggle_mode() {
    local current
    current=$(get_current_mode)
    case "$current" in
        *1440*|*144*)
            apply_mode "1080p"
            ;;
        *)
            apply_mode "2k"
            ;;
    esac
}

interactive_menu() {
    if ! command -v fuzzel >/dev/null 2>&1; then
        echo "Error: fuzzel is required for interactive menu mode." >&2
        exit 1
    fi

    local current
    current=$(get_current_mode)

    local tag_2k=""
    local tag_1080=""

    case "$current" in
        *1440*|*144*)
            tag_2k="  [Active]"
            ;;
        *1080*|*60*)
            tag_1080="  [Active]"
            ;;
    esac

    local opt_2k="󰍹  2K 144Hz (2560x1440 @ 144Hz)$tag_2k"
    local opt_1080="󰍹  1080p 60Hz (1920x1080 @ 60Hz)$tag_1080"

    local choice
    choice=$(printf "%s\n%s\n" "$opt_2k" "$opt_1080" | (fuzzel --dmenu --prompt " Display Mode: " --lines 2 --width 38 2>/dev/null || true))

    if [ -z "$choice" ]; then
        exit 0
    fi

    case "$choice" in
        *1080*)
            apply_mode "1080p"
            ;;
        *1440*|*2K*|*2k*)
            apply_mode "2k"
            ;;
        *)
            exit 0
            ;;
    esac
}

# --- Command-line Dispatcher ---
case "${1:-}" in
    "")
        interactive_menu
        ;;
    status)
        echo "Main display ($OUTPUT) current mode: $(get_current_mode)"
        ;;
    toggle)
        toggle_mode
        ;;
    1080p|1080|60|fhd|FHD)
        apply_mode "1080p"
        ;;
    2k|2K|1440p|1440|144|qhd|QHD)
        apply_mode "2k"
        ;;
    -h|--help|help)
        echo "Usage: $(basename "$0") [1080p | 2k | toggle | status]"
        echo "  (no args)   Open interactive Fuzzel menu"
        echo "  1080p       Switch DP-1 to 1920x1080 @ 60Hz"
        echo "  2k          Switch DP-1 to 2560x1440 @ 144Hz"
        echo "  toggle      Toggle between 1080p and 2K"
        echo "  status      Show current mode"
        ;;
    *)
        echo "Invalid argument: $1" >&2
        echo "Run '$(basename "$0") --help' for usage." >&2
        exit 1
        ;;
esac
