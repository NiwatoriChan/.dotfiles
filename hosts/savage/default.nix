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
    ../../modules/developpement.nix
  ];

  # Hostname
  networking.hostName = "Savage";

  # Fix external display flickering on TVs by disabling Scatter/Gather display memory and expose 1920x1080@59.94Hz mode
  boot.kernelParams = [
  "video=1920x1080@59.94"
  ];

  # Prevent CS35L41 speaker amplifier DSP from hanging during runtime power management
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="spi", DRIVERS=="cs35l41-spi", ATTR{power/control}="on"
  '';

  # Allow Steam and desktop applications full permission to adjust volume in WirePlumber
  services.pipewire.wireplumber.extraConfig."10-permissions" = {
    "access.rules" = [
      {
        matches = [
          {
            "application.name" = "~.*";
          }
        ];
        actions = {
          update-props = {
            "default_permissions" = "all";
          };
        };
      }
    ];
  };

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
