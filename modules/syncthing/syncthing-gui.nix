# Syncthing desktop profile — base service + web GUI config + desktop tray app
{ pkgs, ... }:

{
  imports = [
    ./syncthing.nix
  ];

  services.syncthing = {
    guiAddress = "127.0.0.1:8384"; # Web GUI listening locally
  };

  environment.systemPackages = with pkgs; [
    syncthingtray
  ];
}