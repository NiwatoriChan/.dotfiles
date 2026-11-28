# Steam Deck LCD Jovian profile
{ pkgs, lib, ... }:

{
  jovian = {
    devices.steamdeck = {
      enable = true;
    };
    steam = {
      enable = true;
      autoStart = true;
      user = "niwatorichan";
      desktopSession = "plasma";
    };
    decky-loader = {
      enable = true;
    };
  };

  # Prioritize Jovian's gamescope wrapper over upstream NixOS programs.gamescope
  security.wrappers.gamescope = {
    source = lib.mkForce "${pkgs.gamescope}/bin/gamescope";
    capabilities = lib.mkForce "cap_sys_nice+pie";
  };

  nix.settings = {
    extra-substituters = [ "https://jovian.cachix.org" ];
    extra-trusted-public-keys = [
      "jovian.cachix.org-1:8Vq4Txku6VZIRhYrHYki3Ab9XHJRoWmdYqMqj4rB/Uc="
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
