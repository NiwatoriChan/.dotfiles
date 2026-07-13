# Quickshell bar — Waybar-style status bar for Hyprland
# Uses home-manager's programs.quickshell module for package/service options.
{ config, lib, ... }:

{
  config = lib.mkIf config.programs.quickshell.enable {
    xdg.configFile."quickshell".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/config/quickshell";
  };
}
