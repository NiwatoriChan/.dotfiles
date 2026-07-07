# Hyprland desktop profile — combines system-level and user-level settings
{ pkgs, ... }:

{
  imports = [
    ./wayland-common.nix
  ];

  # --- System-Level (NixOS) Configuration ---

  # Hyprland compositor (customized package to remove UWSM desktop entry from SDDM)
  programs.hyprland = {
    enable = true;
    package = (pkgs.symlinkJoin {
      name = "hyprland-no-uwsm";
      paths = [ pkgs.hyprland ];
      postBuild = ''
        rm -f $out/share/wayland-sessions/hyprland-uwsm.desktop
      '';
    }) // {
      version = pkgs.hyprland.version;
      override = {}: null;
      providedSessions = [ "hyprland" ];
      passthru = {
        providedSessions = [ "hyprland" ];
      };
      meta = pkgs.hyprland.meta // {
        mainProgram = "Hyprland";
        outputsToInstall = [ "out" ];
      };
    };
  };

  # Hyprland-specific packages
  environment.systemPackages = with pkgs; [
    jq  # For advanced monitor screenshot tools in binds
  ];

  # --- User-Level (Home Manager) Configuration ---
  home-manager.users.niwatorichan = { config, ... }: {
    # Hyprland Lua configuration symlink
    home.file.".config/hypr/hyprland.lua".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles-main/home/config/hypr/hyprland.lua";

    # Waybar Status Bar — Hyprland workspace module
    programs.waybar.custom = {
      modules-left = [ "hyprland/workspaces" ];
      extraSettings = {
        "hyprland/workspaces" = {
          format = "{name}";
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
        };
      };
    };
  };
}
