# GNOME desktop profile — combines system-level and user-level settings
{ pkgs, lib, ... }:

{
  # --- System-Level (NixOS) Configuration ---

  # GNOME Desktop Environment
  services.desktopManager.gnome.enable = true;

  # Use SDDM from hosts/common/services.nix rather than enabling GDM alongside it
  services.displayManager.gdm.enable = lib.mkForce false;

  # GNOME-specific packages & extensions
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnomeExtensions.appindicator
  ];

  # Exclude unwanted default GNOME applications
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany
  ];

  # --- User-Level (Home Manager) Configuration ---
  home-manager.users.niwatorichan = { ... }: {
    # Enable AppIndicator tray icon extension for background apps (Nextcloud, etc.)
    dconf.settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [
          "appindicatorsupport@rgcjonas.gmail.com"
        ];
      };
    };
  };
}

