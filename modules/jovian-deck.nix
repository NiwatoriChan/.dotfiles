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
}
