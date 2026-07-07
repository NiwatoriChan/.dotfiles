# Plasma Bigscreen desktop profile — TV / 10-foot interface (combines system-level and user-level settings)
{ pkgs, pkgs-unstable, ... }:

{
  # --- System-Level (NixOS) Configuration ---

  # Overlay: replace kdePackages with the unstable set so plasma6 + bigscreen
  # come from the same channel and stay ABI-compatible.
  nixpkgs.overlays = [
    (final: prev: {
      kdePackages = pkgs-unstable.kdePackages;
    })
  ];

  # KDE Plasma 6 (now pulled from unstable via the overlay above)
  services.desktopManager.plasma6.enable = true;

  # Default SDDM session → Plasma Wayland (bigscreen shell is loaded via env var below)
  services.displayManager.defaultSession = "plasma";

  # Tell plasmashell to load the Bigscreen containment instead of the regular desktop
  environment.sessionVariables.PLASMA_DEFAULT_SHELL = "org.kde.plasma.bigscreen";

  # Companion packages for a media-center / TV setup
  environment.systemPackages = with pkgs.kdePackages; [
    plasma-bigscreen
    qtmultimedia
  ];

  # --- User-Level (Home Manager) Configuration ---
  home-manager.users.niwatorichan = { ... }: {
    imports = [
    ];
  };
}
