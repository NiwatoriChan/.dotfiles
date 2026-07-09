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

  programs.direnv.enable = true;

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # Symlink mimeapps.list out-of-store so applications can edit it
  home.file.".config/mimeapps.list".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/config/mimeapps.list";

  # KDE Connect service and system tray indicator applet
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  home.stateVersion = "26.05";
}
