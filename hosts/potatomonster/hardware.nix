# PotatoMonster hardware — Intel iGPU + NVIDIA 960M
{ config, pkgs, lib, ... }:

{
  services.xserver.videoDrivers = [
    #"modsetting"
    "nvidia"
  ];

  nixpkgs.config.nvidia.acceptLicense = true;

  # Enable OpenGL
  hardware.graphics.enable = true;

  # Pin kernel to a stable 6.x series compatible with legacy_580 driver
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    open = false;

    # Make sure to use the correct version for your GPU!
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      # !!! REPLACE THESE WITH YOUR BUS IDs !!!
      # You can find your Bus IDs by running `lspci | grep VGA` and `lspci | grep 3D`
      intelBusId = "PCI:00:02:0";
      nvidiaBusId = "PCI:02:00:0";
    };
  };

  # Make Steam launch on the dedicated NVIDIA GPU
  programs.steam.package = pkgs.steam.override {
    extraEnv = {
      __NV_PRIME_RENDER_OFFLOAD = "1";
      __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __VK_LAYER_NV_optimus = "NVIDIA_only";
    };
  };

  hardware.cpu.intel.updateMicrocode = true;

 # Disable power-profiles-daemon — conflicts with tlp + auto-cpufreq below
 services.power-profiles-daemon.enable = false;

 services.auto-cpufreq.enable = true;
services.auto-cpufreq.settings = {
  battery = {
     governor = "powersave";
     turbo = "never";
  };
  charger = {
     governor = "performance";
     turbo = "auto";
  };
};

boot.kernelParams = [ "mitigations=off" ];

services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 50;

      };
};

}
