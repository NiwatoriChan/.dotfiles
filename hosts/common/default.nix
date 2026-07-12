# Shared system configuration — imported by all desktop hosts
{ config, pkgs, ... }:

{
  imports = [
    /etc/nixos/hardware-configuration.nix
    ./packages.nix
    ./services.nix
    ../../modules/boot.nix
    ../../modules/secrets.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking (hostname set per-host)
  networking.networkmanager.enable = true;

  # Locale & Timezone
  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  # Console keymap
  console.keyMap = "ca";

  # X11 / Wayland
  services.xserver.enable = false;
  programs.xwayland.enable = true;

  # Configure keymap
  services.xserver.xkb = {
    layout = "ca";
    variant = "";
  };

  # Containers
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  # User account
  users.users."niwatorichan" = {
    isNormalUser = true;
    description = "niwatorichan";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [];
  };

  # Zsh — enabled system-wide so it's a valid login shell
  # (User-level zsh config is in home-manager)
  programs.zsh.enable = true;

  # Firefox
  programs.firefox.enable = true;

  # Polkit — required for pkexec authentication (admin password prompts)
  security.polkit.enable = true;

  # Dconf — required for Home Manager GTK theme management
  programs.dconf.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Permit insecure packages pulled as build dependencies
  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-10.29.2"
  ];

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # AppImage support
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;


  # Thunar File Manager and plugins
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
      thunar-media-tags-plugin
    ];
  };

  # Xfconf configuration daemon (required for saving Thunar preferences)
  programs.xfconf.enable = true;

  # KDE Connect configurations
  home-manager.users.niwatorichan.services.kdeconnect.enable = true;

  networking.firewall = rec {
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };

  # System state version
  system.stateVersion = "26.05";
}
