# KDE Plasma 6 desktop profile — combines system-level and user-level settings
{ pkgs, ... }:

{
  # --- System-Level (NixOS) Configuration ---

  # KDE Plasma 6 (stable, from nixos-26.05)
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
