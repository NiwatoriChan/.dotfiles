# Multimedia profile — media players and streaming applications
{ pkgs, pkgs-stable, ... }:

let
  stremio-steam-launcher = pkgs.writeShellScriptBin "stremio-steam-launcher" ''
    # Clean Steam Runtime environment variables to prevent library clashes
    unset LD_PRELOAD
    unset LD_LIBRARY_PATH
    unset STEAM_RUNTIME
    unset STEAM_ZENITY
    unset STEAM_COMPAT_CLIENT_INSTALL_PATH
    unset STEAM_COMPAT_DATA_PATH

    if [ -x "${pkgs-stable.stremio-linux-shell}/bin/stremio" ]; then
      exec "${pkgs-stable.stremio-linux-shell}/bin/stremio" "$@"
    elif command -v stremio >/dev/null 2>&1; then
      exec stremio "$@"
    elif command -v flatpak >/dev/null 2>&1 && flatpak info com.stremio.Stremio >/dev/null 2>&1; then
      exec flatpak run com.stremio.Stremio "$@"
    else
      echo "Error: Stremio binary not found." >&2
      exit 1
    fi
  '';

  stremio-steam-desktop = pkgs.makeDesktopItem {
    name = "stremio-steam-launcher";
    desktopName = "Stremio (Steam Launcher)";
    comment = "Launch Stremio cleanly from Steam / Gaming Mode";
    exec = "stremio-steam-launcher %u";
    icon = "com.stremio.Stremio";
    categories = [ "Utility" "AudioVideo" "Video" "Player" "Network" ];
    mimeTypes = [ "x-scheme-handler/stremio" ];
    terminal = false;
    type = "Application";
  };
in
{
  environment.systemPackages = [
    pkgs-stable.stremio-linux-shell
    stremio-steam-launcher
    stremio-steam-desktop
    pkgs.vlc
  ];
}
