# Cinnamon desktop profile — combines system-level and user-level settings
{ lib, ... }:

{
  # --- System-Level (NixOS) Configuration ---

  # Cinnamon requires X11 (overrides hosts/common/desktop.nix)
  services.xserver.enable = lib.mkForce true;

  # Cinnamon Desktop Environment
  services.xserver.desktopManager.cinnamon.enable = true;

  # Use SDDM from hosts/common/services.nix rather than LightDM
  services.xserver.displayManager.lightdm.enable = lib.mkForce false;
}
