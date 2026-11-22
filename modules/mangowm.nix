# MangoWM desktop profile — combines system-level and user-level settings
{ pkgs, inputs, ... }:

{
  imports = [
    inputs.mangowm.nixosModules.mango
    ./wayland-common.nix
  ];

  # --- System-Level (NixOS) Configuration ---

  # MangoWM compositor
  programs.mango.enable = true;
  programs.dms-shell.enable = false;


  # --- User-Level (Home Manager) Configuration ---
  home-manager.users.niwatorichan = { config, ... }: {
    # MangoWM configuration symlinks
    home.file.".config/mango/config.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/config/mango/config.conf";

    # Mako Notification Daemon (standalone use on MangoWM without Quickshell)
    home.packages = [ pkgs.mako ];
    services.mako.enable = false;
    xdg.configFile."mako/config".text = ''
      font=Inter Variable 10
      background-color=#121212cc
      text-color=#e0e0e0ff
      border-color=#ffffff20
      border-size=2
      border-radius=12
      default-timeout=5000
      margin=10
      padding=15
    '';

    # Waybar Status Bar — MangoWM workspace module
    programs.waybar.custom = {
      modules-left = [ "ext/workspaces" ];
      extraSettings = {
        "ext/workspaces" = {};
      };
    };
  };
}
