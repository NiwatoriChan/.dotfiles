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

  # Speed up session transitions (gaming mode <-> desktop mode) by reducing timeouts
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';
  systemd.user.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';
}
