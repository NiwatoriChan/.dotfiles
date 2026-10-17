# Desktop environment configuration — imported by graphical desktop/laptop hosts
{ pkgs, ... }:

{
  imports = [
    ./packages.nix
    ./services.nix
    ../../modules/boot.nix
  ];

  # X11 / Wayland
  services.xserver.enable = false;
  programs.xwayland.enable = true;

  # Configure keymap
  services.xserver.xkb = {
    layout = "ca";
    variant = "";
  };

  # Firefox
  programs.firefox.enable = true;

  # OBS Studio
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-vaapi
      obs-vkcapture
      obs-pipewire-audio-capture
    ];
  };

  # LocalSend (AirDrop alternative with firewall rules opened for port 53317)
  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  # Dconf — required for Home Manager GTK theme management
  programs.dconf.enable = true;
  # AppImage support
  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
      extraPkgs = pkgs: with pkgs; [
        curl
        icu
        zlib
        openssl
      ];
    };
  };

  # KDE Connect configurations
  home-manager.users.niwatorichan.services.kdeconnect.enable = true;

  networking.firewall = rec {
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };
}
