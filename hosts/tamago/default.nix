# Tamago — physical machine config
# To switch DE: change the profile import below
{ pkgs, ... }:

{
  imports = [
    ../common
    ./hardware.nix
    ../../modules/hyprland.nix
    #../../modules/kde.nix
    #../../modules/server
    #../../modules/mangowm.nix   # ← swap to ../../modules/hyprland.nix to change DE
    #../../modules/plasma-bigscreen.nix
    ../../modules/virtualisation/vmware.nix
    ../../modules/developpement.nix
    ../../modules/multimedias.nix
    ../../modules/syncthing
  ];

  # Hostname
  networking.hostName = "Tamago";
}
