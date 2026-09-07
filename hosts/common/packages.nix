# Shared system-level packages — installed on all desktop hosts
{ pkgs, lib, config, customPackages, ... }:

{
  environment.systemPackages = with pkgs; [
    # Browser / Custom Packages
    customPackages.brave-origin

    # Terminal emulators & GUI utilities
    kitty
    alacritty
    xhost

    # System & GUI utilities
    bazaar
    distrobox
    mission-center

    # Apps (shared across desktop machines)
    discord
    mpv
    gnome-disk-utility
    moonlight-qt
    nextcloud-client

    # Theming
    papirus-icon-theme
    sddm-astronaut
  ];

  

  # Default applications — Gwenview for images, mpv for video
  xdg.mime.defaultApplications = {
    # Images → Gwenview
    "image/jpeg" = "org.kde.gwenview.desktop";
    "image/png" = "org.kde.gwenview.desktop";
    "image/gif" = "org.kde.gwenview.desktop";
    "image/webp" = "org.kde.gwenview.desktop";
    "image/bmp" = "org.kde.gwenview.desktop";
    "image/tiff" = "org.kde.gwenview.desktop";
    "image/svg+xml" = "org.kde.gwenview.desktop";

    # Video → mpv
    "video/mp4" = "mpv.desktop";
    "video/x-matroska" = "mpv.desktop";
    "video/x-msvideo" = "mpv.desktop";
    "video/webm" = "mpv.desktop";
    "video/quicktime" = "mpv.desktop";
    "video/x-ms-wmv" = "mpv.desktop";
    "video/x-flv" = "mpv.desktop";
    "video/mpeg" = "mpv.desktop";
  };
}
