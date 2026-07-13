# Quickshell — Waybar-style bar

A Quickshell port of the shared Waybar layout from `home/common/waybar.nix`, with WiFi and Bluetooth panels adapted from [tripathiji1312/quickshell](https://github.com/tripathiji1312/quickshell).

## Layout

| Section | Modules |
|---------|---------|
| Left | NixOS power menu, Hyprland workspaces, taskbar |
| Center | Clock, MPRIS |
| Right | Blue light, volume, CPU, memory, battery, WiFi, Bluetooth, system tray |

## Try it (Hyprland)

Replace `waybar` in `home/config/hypr/hyprland.lua` autostart:

```lua
-- hl.exec_cmd("waybar")
hl.exec_cmd("quickshell")
```

Reload Hyprland, or run `quickshell` manually from a graphical session.

## Reload after edits

```bash
./reload-quickshell.sh
```

## Notes

- Hyprland-only for workspaces and taskbar (MangoWM still uses Waybar).
- WiFi/Bluetooth popups use the reference repo's `NetworkPanel` and `BluetoothPanel`.
- Mako remains the notification daemon (`registerServer: false` in `shell.json`).
- Colors match Waybar CSS; pywal overrides apply if `~/.cache/wal/colors.json` exists.
