# Jeff — headless configuration scaffold
{ config, pkgs, lib, ... }:

{
  imports = [
    ../common/base.nix
    ../../modules/server
    ../../modules/mangowm.nix
    ../../modules/developpement.nix
    ../../modules/sunshine.nix
    ../../modules/server/noip.nix
    ./storage.nix
  ];

  # Kernel (CachyOS)
  boot.kernelPackages = lib.mkForce pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  # Nvidia GPU support (GTX 1070 is Pascal, pre-Turing -> use proprietary closed driver)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false; # GTX 1070 (Pascal) MUST use closed modules
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

  # Hostname
  networking.hostName = "Jeff";

  boot.kernelParams = [
    "amd_iommu=off"
  ];
}
