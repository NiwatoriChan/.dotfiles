# Kitty terminal — symlink real config file from dotfiles
{ config, ... }:

{
  home.file.".config/kitty/kitty.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles-main/home/config/kitty/kitty.conf";
}
