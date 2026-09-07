# Desktop environment configuration — imported by graphical desktop/laptop hosts
{ ... }:

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
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;

  # KDE Connect configurations
  home-manager.users.niwatorichan.services.kdeconnect.enable = true

  networking.firewall = rec {
    allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };
}
