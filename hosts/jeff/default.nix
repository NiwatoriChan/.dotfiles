# Jeff — headless configuration scaffold
{ config, pkgs, lib, ... }:

{
  imports = [
    (if builtins.pathExists ./hardware-configuration.nix
     then ./hardware-configuration.nix
     else if builtins.pathExists /etc/nixos/hardware-configuration.nix
     then /etc/nixos/hardware-configuration.nix
     else {})
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
    "processor.max_cstate=1"
    "idle=nomwait"
    "rcu_nocbs=0-11"
  ];

  # Ryzen 1st Gen (Zen 1) C6 idle freeze fix:
  # Hardware C6 states autonomously drop core voltage below stability threshold
  # during idle transitions (e.g. after background jobs finish).
  boot.kernelModules = [ "msr" ];

  systemd.services.zenstates-c6-disable = {
    description = "Disable AMD Ryzen C6 states to prevent idle freezes";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.zenstates}/bin/zenstates --c6-disable";
    };
  };

  # Terminal and Browser
  programs.firefox.enable = true;
  environment.systemPackages = with pkgs; [
    kitty
    zenstates
    msr-tools
  ];
}
