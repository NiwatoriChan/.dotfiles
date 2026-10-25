# Syncthing desktop profile — base service + web GUI config + desktop tray app
{ pkgs, config, lib, ... }:

{
  imports = [
    ./syncthing.nix
  ];

  services.syncthing = {
    guiAddress = "127.0.0.1:8384"; # Web GUI listening locally
  };

  environment.systemPackages = lib.mkIf config.services.syncthing.enable [
    pkgs.syncthingtray
  ];
}