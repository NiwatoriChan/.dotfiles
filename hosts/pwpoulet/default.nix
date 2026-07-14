# PwPoulet — physical machine config
# To switch DE: change the profile import below
{ pkgs, lib, ... }:

{
  imports = [
    ../common
    ../../modules/kde.nix   # ← swap to change DE
    ../../modules/gaming.nix
    ../../modules/sunshine.nix
    ../../modules/developpement.nix
    #../../modules/virtualisation/vmware.nix
    #../../modules/jovian-amd.nix
  ];

  # Bootloader kernel package choice
  boot.kernelPackages = lib.mkForce pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  # Hostname
  networking.hostName = "PwPoulet";
}
