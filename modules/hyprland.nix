# Hyprland desktop profile — combines system-level and user-level settings
{ config, pkgs, inputs, ... }:

{
  imports = [
    ./wayland-common.nix
    inputs.luciole.nixosModules.default
  ];

  # --- System-Level (NixOS) Configuration ---

  # Hyprland compositor (customized package to remove UWSM desktop entry from SDDM)
  programs.hyprland = {
    enable = true;
    withUWSM = false;
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

  # Luciole file manager (Hyprland-only) and default FileChooser portal backend
  programs.luciole.enable = true;

  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  xdg.portal = {
    extraPortals = [
      inputs.luciole.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
    config.hyprland = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "luciole" "gtk" ];
    };
  };

  # Hyprland-specific packages
  environment.systemPackages = with pkgs; [
    config.programs.hyprland.package
    hypridle
    jq  # For advanced monitor screenshot tools in binds
  ];

  # --- User-Level (Home Manager) Configuration ---
  home-manager.users.niwatorichan = { config, ... }: {
    # Hyprland Lua configuration symlink
    home.file.".config/hypr/hyprland.lua".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/config/hypr/hyprland.lua";
    home.file.".config/hypr/hypridle.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/config/hypr/hypridle.conf";

    # Luciole configuration and Kitty-matched neutral dark palette
    home.file.".config/luciole/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/config/luciole/config.toml";
    home.file.".config/luciole/colors.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/config/luciole/colors.toml";

    # Override Luciole's app icon with the cleaner Papirus system-file-manager icon
    xdg.desktopEntries."dev.noctalia.luciole" = {
      name = "Luciole";
      exec = "luciole %U";
      icon = "system-file-manager";
      comment = "Browse files and folders";
      terminal = false;
      type = "Application";
      categories = [ "System" "FileTools" "FileManager" ];
      mimeType = [ "inode/directory" ];
      settings.StartupWMClass = "dev.noctalia.luciole";
    };

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
