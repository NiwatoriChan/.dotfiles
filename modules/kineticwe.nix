# KineticWE desktop profile — combines system-level and user-level settings
{ inputs, pkgs, ... }:

{
  imports = [
    ./wayland-common.nix
    inputs.kineticwe.nixosModules.default
  ];

  # --- System-Level (NixOS) Configuration ---

  # Enable the overlays so pkgs.kineticwe, pkgs.kwin-we, etc. are available
  nixpkgs.overlays = [
    inputs.kineticwe.overlays.default
  ];

  # Enable the programs.kineticwe module
  programs.kineticwe = {
    enable = true;
    # Custom start-kineticwe script to run quickshell and other Hyprland autostarts
    package = pkgs.kineticwe.overrideAttrs (oldAttrs: {
      postInstall = ''
        cat > $out/bin/start-kineticwe << 'EOF'
        #!/bin/bash
        export PATH=${pkgs.xwayland}/bin:${pkgs.kitty}/bin:${pkgs.thunar}/bin:${pkgs.fuzzel}/bin:${pkgs.firefox}/bin:${pkgs.quickshell}/bin:${pkgs.mako}/bin:${pkgs.wpaperd}/bin:${pkgs.networkmanagerapplet}/bin:${pkgs.blueman}/bin:${pkgs.wlsunset}/bin:$PATH
        export XDG_CURRENT_DESKTOP=KineticWE:KDE
        export XDG_SESSION_TYPE=wayland
        export XDG_SESSION_DESKTOP=kineticwe
        export KDE_SESSION_VERSION=6

        # Build the KWin startup payload
        STARTUP_PAYLOAD_DIR="\${XDG_RUNTIME_DIR:-/tmp}/kineticwe-\$USER"
        mkdir -p "\$STARTUP_PAYLOAD_DIR" 2>/dev/null || true
        STARTUP_PAYLOAD="\$STARTUP_PAYLOAD_DIR/startup.sh"

        cat > "\$STARTUP_PAYLOAD" << 'PAYLOADEOF'
        #!/bin/bash
        export XDG_SESSION_TYPE=wayland
        export KDE_SESSION_VERSION=6

        killall -q xdg-desktop-portal-kde xdg-desktop-portal xdg-desktop-portal-gtk 2>/dev/null || true
        sleep 1

        mkdir -p "\$HOME/.local/share" 2>/dev/null || true

        XDG_CURRENT_DESKTOP=KDE nohup ${pkgs.kdePackages.xdg-desktop-portal-kde}/bin/xdg-desktop-portal-kde >"\$HOME/.local/share/xdg-desktop-portal-kde.log" 2>&1 &
        sleep 2
        nohup ${pkgs.xdg-desktop-portal}/bin/xdg-desktop-portal >"\$HOME/.local/share/xdg-desktop-portal.log" 2>&1 &

        # Launch user autostart applications
        nohup quickshell >"\$HOME/.local/share/quickshell.log" 2>&1 &
        nohup mako >"\$HOME/.local/share/mako.log" 2>&1 &
        nohup wpaperd >"\$HOME/.local/share/wpaperd.log" 2>&1 &
        nohup nm-applet --indicator >"\$HOME/.local/share/nm-applet.log" 2>&1 &
        nohup blueman-applet >"\$HOME/.local/share/blueman-applet.log" 2>&1 &
        nohup wlsunset -t 4000 -T 4000 >"\$HOME/.local/share/wlsunset.log" 2>&1 &

        sleep 5
        PAYLOADEOF

        chmod +x "\$STARTUP_PAYLOAD"

        # Stop any competing global-shortcuts daemon
        systemctl --user stop plasma-kglobalaccel.service 2>/dev/null || true
        pkill -x kglobalacceld 2>/dev/null || true

        exec "${pkgs.kwin-we}/bin/kinetic-we" --xwayland "\$STARTUP_PAYLOAD"
        EOF
        chmod +x $out/bin/start-kineticwe
      '';
    });
  };

  # --- User-Level (Home Manager) Configuration ---
  home-manager.users.niwatorichan = { config, ... }: {
    imports = [
      inputs.kineticwe.homeModules.default
    ];

    programs.kineticwe = {
      enable = true;
    };

    # Map the KDE/KWin configuration files directly from the dotfiles repository
    home.file.".config/kwinrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/kde-config/kwinrc";
    home.file.".config/kglobalshortcutsrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/kde-config/kglobalshortcutsrc";
    home.file.".config/kdeglobals".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/kde-config/kdeglobals";
    home.file.".config/kcminputrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/kde-config/kcminputrc";
    home.file.".config/dolphinrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/home/kde-config/dolphinrc";
  };
}
