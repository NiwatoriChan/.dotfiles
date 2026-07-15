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

  # Add "Return to Gaming Mode" shortcut on Desktop
  home-manager.users.niwatorichan = { pkgs, ... }: {
    home.file."Desktop/Return-to-Gaming-Mode.desktop" = {
      text = ''
        [Desktop Entry]
        Name=Return to Gaming Mode
        Exec=steamos-session-select gamescope
        Icon=steam
        Terminal=false
        Type=Application
        StartupNotify=false
      '';
      executable = true;
    };
  };

  # Speed up session transitions (gaming mode <-> desktop mode) by reducing timeouts
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';
  systemd.user.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';
}
