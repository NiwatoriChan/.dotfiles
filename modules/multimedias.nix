# Multimedia profile — media players and streaming applications
{ pkgs, pkgs-stable, ... }:

{
  environment.systemPackages = [
    pkgs-stable.stremio-linux-shell
    pkgs.vlc
  ];
}
