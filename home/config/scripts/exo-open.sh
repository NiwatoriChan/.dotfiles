#!/usr/bin/env bash
# Compatibility wrapper for exo-open on systems without xfce4-exo

dir=""
launch_term=false

while [ $# -gt 0 ]; do
    case "$1" in
        --working-directory)
            dir="$2"
            shift 2
            ;;
        --launch)
            if [ "$2" = "TerminalEmulator" ]; then
                launch_term=true
            fi
            shift 2
            ;;
        TerminalEmulator)
            launch_term=true
            shift
            ;;
        *)
            if [ -d "$1" ]; then
                dir="$1"
            fi
            shift
            ;;
    esac
done

if [ "$launch_term" = true ] || [ -n "$dir" ]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -x "$script_dir/thunar-open-terminal.sh" ]; then
        exec "$script_dir/thunar-open-terminal.sh" "$dir"
    elif [ -x "$HOME/.local/bin/thunar-open-terminal" ]; then
        exec "$HOME/.local/bin/thunar-open-terminal" "$dir"
    else
        exec kitty ${dir:+--directory "$dir"}
    fi
else
    if command -v xdg-open >/dev/null 2>&1; then
        exec xdg-open "$@"
    fi
fi
