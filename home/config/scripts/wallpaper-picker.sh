#!/usr/bin/env bash
# ==============================================================================
# Wallpaper Manager & Interactive Picker for Hyprland using awww (swww) & Fuzzel
# ==============================================================================

set -eo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/wallpaper}"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper"
STATE_FILE="$STATE_DIR/state.json"

mkdir -p "$WALLPAPER_DIR" "$STATE_DIR"

# Ensure awww-daemon is running
ensure_daemon() {
    if ! awww query >/dev/null 2>&1; then
        # Clean up any stale daemon process or socket
        pkill -x awww-daemon >/dev/null 2>&1 || true
        sleep 0.1
        awww-daemon >/dev/null 2>&1 &
        # Give daemon a brief moment to initialize the socket
        for _ in {1..20}; do
            if awww query >/dev/null 2>&1; then
                break
            fi
            sleep 0.1
        done
    fi
}

# Apply wallpaper with smooth transition
apply_wallpaper() {
    local target="$1"      # Output name or "all"
    local img_path="$2"    # Absolute path to image

    if [ ! -f "$img_path" ]; then
        echo "Error: Image not found: $img_path" >&2
        return 1
    fi

    ensure_daemon

    local transition_args=(
        --transition-type wipe
        --transition-angle 30
        --transition-duration 1.2
        --transition-fps 60
    )

    if [ "$target" = "all" ] || [ -z "$target" ]; then
        awww img "${transition_args[@]}" "$img_path"
        save_state "all" "$img_path"
        notify_user "All Displays" "$img_path"
    else
        awww img -o "$target" "${transition_args[@]}" "$img_path"
        save_state "$target" "$img_path"
        notify_user "$target" "$img_path"
    fi
}

# Save wallpaper state per output to JSON
save_state() {
    local target="$1"
    local img_path="$2"
    
    if [ ! -f "$STATE_FILE" ]; then
        echo "{}" > "$STATE_FILE"
    fi

    if [ "$target" = "all" ]; then
        local monitors
        monitors=$(get_monitors_raw)
        for mon in $monitors; do
            local tmp
            tmp=$(jq --arg k "$mon" --arg v "$img_path" '.[$k] = $v' "$STATE_FILE" 2>/dev/null || echo "{\"$mon\": \"$img_path\"}")
            echo "$tmp" > "$STATE_FILE"
        done
    else
        local tmp
        tmp=$(jq --arg k "$target" --arg v "$img_path" '.[$k] = $v' "$STATE_FILE" 2>/dev/null || echo "{\"$target\": \"$img_path\"}")
        echo "$tmp" > "$STATE_FILE"
    fi
}

# Notification helper
notify_user() {
    local target="$1"
    local img_path="$2"
    local filename
    filename=$(basename "$img_path")

    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Wallpaper" -i "$img_path" "Wallpaper Updated" "Applied $filename to $target" 2>/dev/null || true
    fi
}

# Get list of connected monitor names (raw list)
get_monitors_raw() {
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl monitors -j 2>/dev/null | jq -r '.[].name' || true
    elif command -v awww >/dev/null 2>&1; then
        awww query 2>/dev/null | awk '{print $1}' | tr -d ':' || true
    fi
}

# Get list of connected monitors with human descriptions
get_monitors_pretty() {
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl monitors -j 2>/dev/null | jq -r '.[] | "\(.name) (\(.description // .model // "Display"))"' || true
    else
        get_monitors_raw
    fi
}

# Get all wallpapers in wallpaper directory
get_wallpapers() {
    find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) | sort
}

# Restore wallpapers from saved state or fallback
restore_wallpapers() {
    ensure_daemon

    local monitors
    monitors=$(get_monitors_raw)

    if [ -z "$monitors" ]; then
        return 0
    fi

    local wallpapers
    mapfile -t wallpapers < <(get_wallpapers)

    if [ ${#wallpapers[@]} -eq 0 ]; then
        return 0
    fi

    for mon in $monitors; do
        local saved_img=""
        if [ -f "$STATE_FILE" ]; then
            saved_img=$(jq -r --arg k "$mon" '.[$k] // empty' "$STATE_FILE" 2>/dev/null || true)
        fi

        if [ -n "$saved_img" ] && [ -f "$saved_img" ]; then
            awww img -o "$mon" --transition-type none "$saved_img"
        else
            # Pick a random wallpaper as fallback
            local rand_img="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
            awww img -o "$mon" --transition-type none "$rand_img"
            save_state "$mon" "$rand_img"
        fi
    done
}

# Set random wallpaper
random_wallpaper() {
    local target="${1:-all}"
    local wallpapers
    mapfile -t wallpapers < <(get_wallpapers)

    if [ ${#wallpapers[@]} -eq 0 ]; then
        echo "No wallpapers found in $WALLPAPER_DIR" >&2
        return 1
    fi

    if [ "$target" = "all" ]; then
        local monitors
        monitors=$(get_monitors_raw)
        for mon in $monitors; do
            local rand_img="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
            apply_wallpaper "$mon" "$rand_img"
        done
    else
        local rand_img="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
        apply_wallpaper "$target" "$rand_img"
    fi
}

# Interactive selection using Fuzzel
interactive_picker() {
    if ! command -v fuzzel >/dev/null 2>&1; then
        echo "Error: fuzzel is required for interactive mode." >&2
        exit 1
    fi

    # Step 1: Select Screen
    local monitor_choices="🖥️  All Displays\n"
    local raw_monitors
    mapfile -t raw_monitors < <(get_monitors_pretty)

    for m in "${raw_monitors[@]}"; do
        [ -n "$m" ] && monitor_choices+="🖥️  $m\n"
    done

    local selected_monitor_line
    selected_monitor_line=$(echo -e "$monitor_choices" | sed '/^$/d' | fuzzel --dmenu --prompt "Select Screen: ")

    [ -z "$selected_monitor_line" ] && exit 0

    local target_output="all"
    if [[ "$selected_monitor_line" != *"All Displays"* ]]; then
        # Extract monitor name (e.g. DP-1 from "🖥️  DP-1 (LG QHD)")
        target_output=$(echo "$selected_monitor_line" | awk '{print $2}')
    fi

    # Step 2: Select Wallpaper or Action
    local wallpapers
    mapfile -t wallpapers < <(get_wallpapers)

    local wallpaper_choices="🎲 Random Wallpaper\n📂 Open Wallpaper Folder\n"
    for w in "${wallpapers[@]}"; do
        local rel_path="${w#$WALLPAPER_DIR/}"
        wallpaper_choices+="🖼️  $rel_path\n"
    done

    local selected_wp_line
    selected_wp_line=$(echo -e "$wallpaper_choices" | sed '/^$/d' | fuzzel --dmenu --prompt "Select Wallpaper for [$target_output]: ")

    [ -z "$selected_wp_line" ] && exit 0

    case "$selected_wp_line" in
        *"Random Wallpaper"*)
            random_wallpaper "$target_output"
            ;;
        *"Open Wallpaper Folder"*)
            if command -v thunar >/dev/null 2>&1; then
                thunar "$WALLPAPER_DIR" &
            elif command -v xdg-open >/dev/null 2>&1; then
                xdg-open "$WALLPAPER_DIR" &
            fi
            ;;
        *)
            local chosen_rel="${selected_wp_line#🖼️  }"
            local full_path="$WALLPAPER_DIR/$chosen_rel"
            if [ -f "$full_path" ]; then
                apply_wallpaper "$target_output" "$full_path"
            else
                echo "Error: Could not resolve file $full_path" >&2
            fi
            ;;
    esac
}

# Main CLI dispatch
case "$1" in
    --restore)
        restore_wallpapers
        ;;
    --random)
        random_wallpaper "${2:-all}"
        ;;
    --set)
        if [ -z "$2" ]; then
            echo "Usage: $0 --set <image_path> [output]" >&2
            exit 1
        fi
        apply_wallpaper "${3:-all}" "$2"
        ;;
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  (no args)                   Launch interactive Fuzzel picker"
        echo "  --restore                   Restore saved wallpapers per monitor"
        echo "  --random [output]           Set random wallpaper (all or specific output)"
        echo "  --set <image_path> [output] Set specific wallpaper (all or specific output)"
        echo "  --help                      Show this help message"
        ;;
    *)
        if command -v quickshell >/dev/null 2>&1 && pgrep -x quickshell >/dev/null 2>&1; then
            quickshell ipc call wallpaper toggle
        else
            interactive_picker
        fi
        ;;
esac
