# Desktop environment configuration — imported by graphical desktop/laptop hosts
{ pkgs, ... }:

{
  imports = [
    ./packages.nix
    ./services.nix
    ../../modules/boot.nix
  ];

  # X11 / Wayland
  services.xserver.enable = false;
  programs.xwayland.enable = true;

  # Configure keymap
  services.xserver.xkb = {
    layout = "ca";
    variant = "";
  };

  # Firefox
  programs.firefox.enable = true;

  # Dconf — required for Home Manager GTK theme management
  programs.dconf.enable = true;
  # AppImage support
  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
      extraPkgs = pkgs: with pkgs; [
        curl
        icu
        zlib
        openssl
      ];
    };
  };

  # KDE Connect configurations
  home-manager.users.niwatorichan.services.kdeconnect.enable = true;

  networking.firewall = rec {
    # Allow DHCP and DNS for NetworkManager connection sharing (Ethernet sharing)
    allowedUDPPorts = [ 53 67 68 ];
    allowedTCPPorts = [ 53 ];
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = allowedTCPPortRanges;
    # Avoid dropping forwarded packets via reverse path filter
    checkReversePath = "loose";
  };
}
