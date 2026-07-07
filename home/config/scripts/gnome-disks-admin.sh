#!/bin/sh
# Wrapper script to launch GNOME Disk Utility (gnome-disks) as root.
# Grants the root user X11 display access, then runs gnome-disks via pkexec
# with the necessary environment variables forwarded so the GUI can connect
# to the user's current Wayland/X11 session.

xhost +si:localuser:root >/dev/null 2>&1

pkexec env \
  DISPLAY="$DISPLAY" \
  WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
  XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
  GTK_THEME="Adwaita:dark" \
  ADW_DEBUG_COLOR_SCHEME="prefer-dark" \
  ADW_DISABLE_PORTAL=1 \
  gnome-disks "$@"
