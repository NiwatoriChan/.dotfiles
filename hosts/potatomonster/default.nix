# PotatoMonster — physical machine config
# To switch DE: change the profile import below
{ pkgs, ... }:

{
  imports = [
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
    ../../modules/kodi.nix
    ../../modules/multimedias.nix
  ];

  # Hostname
  networking.hostName = "PotatoMonster";
}
