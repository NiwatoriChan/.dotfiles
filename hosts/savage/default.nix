# Savage — Steam Deck LCD configuration
{ pkgs, lib, ... }:

{
  imports = [
    ../common
    ../../modules/kde.nix
    ../../modules/gaming.nix
    ../../modules/jovian-deck.nix
    ../../modules/sunshine.nix
    ../../modules/multimedias.nix
  ];

  # Hostname
  networking.hostName = "Savage";

  # Fix external display flickering on older TVs by forcing 1080p@60Hz and disabling Scatter/Gather display memory
  boot.kernelParams = [ 
    "amdgpu.sg_display=0" 
    "video=DP-1:1920x1080@60e"
    "video=DP-2:1920x1080@60e"
    "video=HDMI-A-1:1920x1080@60e"
  ];

  # Add "Return to Gaming Mode" shortcut on Desktop
  home-manager.users.niwatorichan = { pkgs, ... }: {
    home.file."Desktop/Return-to-Gaming-Mode.desktop" = {
      text = ''
        [Desktop Entry]
        Name=Return to Gaming Mode
        Exec=/run/current-system/sw/bin/steamos-session-select gamescope
        Icon=steam
        Terminal=false
        Type=Application
        StartupNotify=false
      '';
      executable = true;
    };
  };

  # Speed up session transitions (gaming mode <-> desktop mode) by reducing timeouts
  systemd.settings = {
    Manager = {
      DefaultTimeoutStopSec = "10s";
    };
  };
}
