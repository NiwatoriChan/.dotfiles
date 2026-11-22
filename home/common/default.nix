# Shared home-manager configuration — imported by all desktop host profiles
{ config, pkgs, ... }:

{
  imports = [
    ./shell.nix
    ./git.nix
    ./kitty.nix
    ./packages.nix
    ./webapps.nix
    ./desktopshortcutsoverride.nix
  ];

  home.username = "niwatorichan";
  home.homeDirectory = "/home/niwatorichan";

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];

  programs.direnv.enable = true;

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # Symlink mimeapps.list out-of-store so applications can edit it
  home.file.".config/mimeapps.list".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/config/mimeapps.list";

  # Enable CEF remote debugging for Steam (required for Decky Loader to inject)
  home.file.".steam/steam/.cef-enable-remote-debugging".text = "";

  # KDE Connect background daemon (launch kdeconnect-app on demand; skip persistent tray applet)
  services.kdeconnect = {
    enable = true;
    indicator = false;
  };

  home.stateVersion = "26.05";
}
