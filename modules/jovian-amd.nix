# General AMD GPU PC Jovian profile
{ pkgs, lib, ... }:

{
  jovian = {
    steam = {
      enable = true;
      autoStart = false; # Do not autoStart Gaming Mode on boot for the daily driver
      user = "niwatorichan";
    };
    hardware.has.amd.gpu = true;
  };

  nix.settings = {
    extra-substituters = [ "https://jovian.cachix.org" ];
    extra-trusted-public-keys = [
      "jovian.cachix.org-1:8Vq4Txku6VZIRhYrHYki3Ab9XHJRoWmdYqMqj4rB/Uc="
    ];
  };
}
