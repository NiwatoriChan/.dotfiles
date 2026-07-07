#!/usr/bin/env bash
# Power Menu — launched from the NixOS waybar button
# Uses fuzzel as the selection menu

choice=$(printf " Shutdown\n Reboot\n Logout\n About This System" | fuzzel --dmenu --prompt "  " --width 28 --lines 4)

case "$choice" in
    *"Shutdown"*)
        systemctl poweroff
        ;;
    *"Reboot"*)
        systemctl reboot
        ;;
    *"Logout"*)
        # Works with both Hyprland and MangoWM
        if pgrep -x Hyprland >/dev/null; then
            hyprctl dispatch exit
        elif pgrep -x mango >/dev/null; then
            mmsg dispatch quit
        else
            # Generic wayland logout
            loginctl terminate-session "$XDG_SESSION_ID"
        fi
        ;;
    *"About This System"*)
        kitty --class nixos-about --title "About This System" sh -c "fastfetch; echo; read -n 1 -s -r -p '  Press any key to close...'"
        ;;
esac
