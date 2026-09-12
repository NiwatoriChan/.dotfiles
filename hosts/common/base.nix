# Base system configuration — shared across all hosts (desktop and headless server)
{ pkgs, ... }:

{
  imports = [
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

  # Nix-ld for running unpatched dynamic binaries
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    glibc
  ];

  # SSH daemon configuration
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
      AllowUsers = [ "niwatorichan" ];
      MaxAuthTries = 3;
      PerSourcePenalties = "crash:3600s authfail:3600s max:86400s";
    };
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
    extraGroups = [ "networkmanager" "wheel" "input" "uinput" ];
    shell = pkgs.zsh;
    packages = with pkgs; [];
  };

  # Zsh — enabled system-wide so it's a valid login shell
  programs.zsh.enable = true;

  # Polkit — required for privilege escalation
  security.polkit.enable = true;

  # SSD TRIM (weekly via systemd timer)
  services.fstrim.enable = true;

  # Core command-line utilities
  environment.systemPackages = with pkgs; [
    neovim
    wget
    git
    fastfetch
    gnumake
    curl
    jq
    bat
    ripgrep
    fd
    zip
    tree
    nnn
    gh
    htop
    btop
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Permit insecure packages pulled as build dependencies
  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-9.15.9"
    "pnpm-10.29.2"
  ];

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System state version
  system.stateVersion = "26.05";
}
