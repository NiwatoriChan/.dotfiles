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
}
