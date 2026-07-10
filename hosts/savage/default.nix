# Savage — Steam Deck LCD configuration
{ pkgs, lib, ... }:

{
  imports = [
    ../common
    ../../modules/kde.nix
    ../../modules/gaming.nix
    ../../modules/jovian-deck.nix
    ../../modules/sunshine.nix
  ];

  # Hostname
  networking.hostName = "Savage";
}
