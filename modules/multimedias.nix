# Multimedia profile — media players and streaming applications
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    stremio-linux-shell
    vlc
  ];
}
