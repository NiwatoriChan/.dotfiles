# KDE Plasma 6 desktop profile — combines system-level and user-level settings
{ pkgs, pkgs-unstable, ... }:

{
  # --- System-Level (NixOS) Configuration ---

  # Overlay: replace kdePackages with the unstable set so the latest KDE is always used.
  nixpkgs.overlays = [
    (final: prev: {
      kdePackages = pkgs-unstable.kdePackages;
    })
  ];

  # KDE Plasma 6 (now pulled from unstable via the overlay above)
  services.desktopManager.plasma6.enable = true;

  # KDE-specific packages
  environment.systemPackages = with pkgs; [
    kdePackages.dolphin
    kdePackages.qtmultimedia
  ];

  # --- User-Level (Home Manager) Configuration ---
  home-manager.users.niwatorichan = { ... }: {
    imports = [
    ];
  };
}
