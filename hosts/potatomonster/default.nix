# PotatoMonster — physical machine config
# To switch DE: change the profile import below
{ pkgs, ... }:

{
  imports = [
    (if builtins.pathExists ./hardware-configuration.nix
     then ./hardware-configuration.nix
     else if builtins.pathExists /etc/nixos/hardware-configuration.nix
     then /etc/nixos/hardware-configuration.nix
     else {})
    ../common
    ./hardware.nix
    ../../modules/hyprland.nix
    #../../modules/kde.nix
    #../../modules/server
    ../../modules/gaming.nix
    ../../modules/sunshine.nix
    #../../modules/mangowm.nix   # ← swap to ../../modules/hyprland.nix to change DE
    #../../modules/plasma-bigscreen.nix
    ../../modules/virtualisation/vmware.nix
    ../../modules/developpement.nix
    ../../modules/multimedias.nix
    ../../modules/syncthing
  ];

  # Hostname
  networking.hostName = "PotatoMonster";
}
