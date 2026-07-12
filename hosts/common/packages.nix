# Shared system-level packages — installed on all desktop hosts
{ pkgs, heliumPkg, ... }:

{
  environment.systemPackages = with pkgs; [
    # Browser
    heliumPkg

    # Command line utilities
    neovim
    wget
    git
    fastfetch
    kitty
    gnumake
    curl
    jq
    bat
    alacritty
    antigravity
    ripgrep
    xhost
    fd
    zip
    tree
    nnn
    gh

    # System
    bazaar
    distrobox
    mission-center

    # Apps (shared across machines)
    discord
    zed-editor
    mpv
    emacs-pgtk
    gnome-disk-utility
    moonlight-qt

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
