# PetitePatate — Pinebook Pro configuration
{ config, pkgs, lib, ... }:

{
  imports = [
    ../common
    ../../modules/hyprland.nix
  ];

  # Hostname
  networking.hostName = "petitepatate";

  # Override EFI variable touching since Pinebook Pro has no NVRAM for it
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  # Recommended kernel parameters for display/boot console on Rockchip
  boot.kernelParams = [ "console=tty0" ];

  # Configure CPU governor for the Rockchip RK3399 big.LITTLE SoC
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  # Apply CPU/GPU undervolting and overclocking kernel patch
  boot.kernelPatches = [
    {
      name = "pbp-undervolt-overclock";
      patch = ./patches/0001-RK3399-Undervolt-and-Overclock-dtb-for-Pinebook-Pro.patch;
    }
  ];
}
