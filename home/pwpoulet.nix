# PwPoulet home-manager profile
{ config, pkgs, ... }:

{
  imports = [
    ./common
  ];

  # Packages specific to PwPoulet display management
  home.packages = with pkgs; [
    wlr-randr
    xrandr
    libnotify
  ];

  # Desktop entry for display resolution switcher (DP-1)
  xdg.desktopEntries."switch-display-pwpoulet" = {
    name = "Toggle Display Settings";
    genericName = "Toggle Display Settings";
    comment = "Switch main display (DP-1) between 1080p 60Hz and 2K 144Hz";
    exec = "${config.home.homeDirectory}/.dotfiles/home/config/scripts/switch-display-pwpoulet.sh";
    icon = "video-display";
    terminal = false;
    type = "Application";
    categories = [ "Settings" "HardwareSettings" "Utility" ];
    settings = {
      Keywords = "display;toggle;resolution;settings;settngs;screen;1080p;2k;144hz;pwpoulet;";
    };
    actions = {
      "mode-2k" = {
        name = "2K 144Hz (2560x1440 @ 144Hz)";
        exec = "${config.home.homeDirectory}/.dotfiles/home/config/scripts/switch-display-pwpoulet.sh 2k";
      };
      "mode-1080p" = {
        name = "1080p 60Hz (1920x1080 @ 60Hz)";
        exec = "${config.home.homeDirectory}/.dotfiles/home/config/scripts/switch-display-pwpoulet.sh 1080p";
      };
    };
  };

  # CLI helper symlink in ~/.local/bin
  home.file.".local/bin/switch-display-pwpoulet".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/config/scripts/switch-display-pwpoulet.sh";
}

