# MangoWM desktop profile — combines system-level and user-level settings
{ pkgs, ... }:

{
  imports = [
    ./wayland-common.nix
  ];

  # --- System-Level (NixOS) Configuration ---

  # MangoWM compositor
  programs.mango.enable = true;
  programs.dms-shell.enable = false;

  # MangoWM-specific packages
  environment.systemPackages = with pkgs; [
    nemo
  ];

  # --- User-Level (Home Manager) Configuration ---
  home-manager.users.niwatorichan = { config, ... }: {
    # MangoWM configuration symlinks
    home.file.".config/mango/config.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles-main/home/config/mango/config.conf";

    # Waybar Status Bar — MangoWM workspace module
    programs.waybar.custom = {
      modules-left = [ "ext/workspaces" ];
      extraSettings = {
        "ext/workspaces" = {};
      };
    };
  };
}
