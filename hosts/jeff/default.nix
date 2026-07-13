# Jeff — headless configuration scaffold
{ config, pkgs, ... }:

{
  imports = [
    # Server does NOT import ../common — it has its own minimal base
    /etc/nixos/hardware-configuration.nix
    ../../modules/server
  ];

  # Nvidia GPU support (GTX 1070 is Pascal, pre-Turing -> use proprietary closed driver)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false; # GTX 1070 (Pascal) MUST use closed modules
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hostname
  networking.hostName = "Jeff";
  networking.networkmanager.enable = true;

  # Locale & Timezone
  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";
  console.keyMap = "ca";

  # User account
  users.users."niwatorichan" = {
    isNormalUser = true;
    description = "niwatorichan";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here
      # "ssh-ed25519 AAAA..."
    ];
  };

  programs.zsh.enable = true;

  # Additional server-specific configurations can be added here.
  # Base SSH, firewall, and minimal packages are now defined in ../../modules/server.

  # Containers
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  # Nix settings
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "26.05";
}
