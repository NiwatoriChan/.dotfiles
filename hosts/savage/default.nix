# Savage — Steam Deck LCD configuration
{ pkgs, lib, ... }:

{
  imports = [
    ../common
    ../../modules/kde.nix
    ../../modules/gaming.nix
  ];

  # Jovian-NixOS Steam Deck Configuration
  jovian = {
    devices.steamdeck = {
      enable = true;
    };
    steam = {
      enable = true;
      autoStart = true;
      user = "niwatorichan";
      desktopSession = "plasma";
    };
  };

  # Hostname
  networking.hostName = "Savage";
}
