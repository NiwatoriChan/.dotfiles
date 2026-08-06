# Savage — Steam Deck LCD configuration
{ pkgs, lib, config, ... }:

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

  # Force kernel DRM subsystem to expose 1920x1080@59.94Hz mode if not exposed by monitor EDID
  boot.kernelParams = [
    "video=1920x1080@59.94"
  ];

  # Add "Return to Gaming Mode" shortcut on Desktop
  home-manager.users.niwatorichan = { pkgs, ... }: {
    home.file."Desktop/Return-to-Gaming-Mode.desktop".source =
      (pkgs.makeDesktopItem {
        desktopName = "Return to Gaming Mode";
        exec = "qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout";
        icon = "steam";
        name = "Return-to-Gaming-Mode";
        startupNotify = false;
        terminal = false;
        type = "Application";
      })
      + "/share/applications/Return-to-Gaming-Mode.desktop";

    # Boot in desktop mode instead of gaming mode by default
    # https://github.com/Jovian-Experiments/Jovian-NixOS/discussions/488
    xdg.stateFile."steamos-session-select" = {
      text = config.jovian.steam.desktopSession;
    };
  };

  # Speed up session transitions (gaming mode <-> desktop mode) by reducing timeouts
  systemd.settings = {
    Manager = {
      DefaultTimeoutStopSec = "10s";
    };
  };
}
