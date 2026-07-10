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
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
