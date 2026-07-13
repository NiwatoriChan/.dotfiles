# Shared Wayland desktop profile — combines system-level and user-level settings
{ config, pkgs, ... }:

{
  # --- System-Level (NixOS) Configuration ---

  # Wayland utility packages shared across tiling WMs
  environment.systemPackages = with pkgs; [
    alsa-utils
    brightnessctl
    grim
    slurp
    wl-clipboard
    swaybg
    networkmanagerapplet
    blueman
    wpaperd
    kdePackages.gwenview
    wlsunset
    opencode-desktop
    pavucontrol
    pwvucontrol
    playerctl
  ];

  services.blueman.enable = true;

  # Thunar File Manager and plugins
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
      thunar-media-tags-plugin
    ];
  };

  # Xfconf configuration daemon (required for saving Thunar preferences)
  programs.xfconf.enable = true;

  # Default applications — Directories → Thunar
  xdg.mime.defaultApplications = {
    "inode/directory" = "thunar.desktop";
  };

  fonts.packages = with pkgs; [
    font-awesome
    nerd-fonts.symbols-only
    nerd-fonts.hack
    noto-fonts-color-emoji
  ];

  # --- User-Level (Home Manager) Configuration ---
  home-manager.users.niwatorichan = { config, pkgs, ... }: {
    imports = [
      ../home/common/waybar.nix
      ../home/common/quickshell.nix
    ];

    programs.quickshell.enable = true;

    # Qt theming — use qtct to manage styling for any Qt apps
    qt = {
      enable = true;
      platformTheme.name = "qtct";
    };

    # GTK theming to set default theme and prefer dark mode
    gtk = {
      enable = true;
      theme = {
        name = "Breeze-Dark";
        package = pkgs.kdePackages.breeze-gtk;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-decoration-layout = ":minimize,maximize,close";
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-decoration-layout = ":minimize,maximize,close";
      };
    };

    # Set pointer cursor to Breeze (from KDE)
    home.pointerCursor = {
      gtk.enable = true;
      package = pkgs.kdePackages.breeze;
      name = "breeze_cursors";
      size = 24;
    };

    # Configure qt5ct and qt6ct — plain config files symlinked from dotfiles
    home.file.".config/qt5ct/colors/darker.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/config/qt5ct/colors/darker.conf";
    home.file.".config/qt5ct/qt5ct.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/config/qt5ct/qt5ct.conf";
    home.file.".config/qt6ct/colors/darker.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/config/qt6ct/colors/darker.conf";
    home.file.".config/qt6ct/qt6ct.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/config/qt6ct/qt6ct.conf";

    home.file.".config/waybar/scripts/wlsunset.sh".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/config/waybar/scripts/wlsunset.sh";
    home.file.".config/waybar/scripts/power-menu.sh".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/config/waybar/scripts/power-menu.sh";
    home.file.".local/bin/gnome-disks-admin".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/config/scripts/gnome-disks-admin.sh";

    home.packages = with pkgs; [
      libsForQt5.qt5ct
      kdePackages.qt6ct
    ];

    # Doom Emacs config symlink
    home.file.".config/doom".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/config/doom";

    # Blurry transparent centered Wayland application launcher with icons (Fuzzel)
    programs.fuzzel = {
      enable = true;
      settings = {
        main = {
          font = "Inter Variable:size=12";
          terminal = "kitty";
          prompt = "  run: ";
          icon-theme = "Papirus-Dark";
          width = 50;
          lines = 10;
          horizontal-pad = 20;
          vertical-pad = 20;
          inner-pad = 12;
        };
        colors = {
          background = "121212CC"; # 80% opacity dark grey
          text = "E0E0E0FF";
          prompt = "FFFFFFFF";
          input = "FFFFFFFF";
          match = "00FFFFFF"; # Match highlight in cyan
          selection = "FFFFFF1A"; # 10% opacity selection highlight
          selection-text = "FFFFFFFF";
          selection-match = "00FFFFFF";
          border = "FFFFFF20"; # 12.5% opacity white border
        };
        border = {
          width = 2;
          radius = 12;
        };
      };
    };

    # Mako Notification Daemon
    services.mako = {
      enable = true;
      extraConfig = ''
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
    };

    # wpaperd Wallpaper Daemon
    services.wpaperd = {
      enable = true;
      settings = {
        default = {
          path = "/home/niwatorichan/wallpaper";
          duration = "15m";
          sorting = "random";
        };
      };
    };
    systemd.user.services.wpaperd.Install.WantedBy = pkgs.lib.mkForce [ ];

    # KDE PolicyKit Authentication Agent for Wayland WMs (MangoWM, Hyprland)
    systemd.user.services.polkit-kde-authentication-agent-1 = {
      Unit = {
        Description = "KDE PolicyKit Authentication Agent";
        Wants = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    # Xfconf settings for Thunar default preferences
    xfconf.settings = {
      thunar = {
        "last-view" = "ThunarIconView";
        "misc-show-hidden" = true;            # Always show hidden files
        "misc-single-click-select" = false;   # Require double click to open
        "misc-remember-geometry" = true;      # Keep window size preferences
        "misc-volume-management" = true;      # Enable volman plugin volume management
      };
    };
  };
}
