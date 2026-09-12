# PwPoulet — physical machine config
# To switch DE: change the profile import below
{ pkgs, lib, ... }:

{
  imports = [
    (if builtins.pathExists ./hardware-configuration.nix
     then ./hardware-configuration.nix
     else if builtins.pathExists /etc/nixos/hardware-configuration.nix
     then /etc/nixos/hardware-configuration.nix
     else {})
    ../common
    ../../modules/hyprland.nix   # ← swap to change DE
    #../../modules/kde.nix
    ../../modules/gaming.nix
    ../../modules/sunshine.nix
    ../../modules/developpement.nix
    ../../modules/syncthing
    #../../modules/virtualisation/vmware.nix
    #../../modules/jovian-amd.nix
  ];

  # Bootloader kernel package choice
  boot.kernelPackages = lib.mkForce pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  # Hostname
  networking.hostName = "PwPoulet";
}
