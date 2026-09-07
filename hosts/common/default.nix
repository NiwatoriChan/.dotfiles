# Shared desktop system configuration — imported by all desktop hosts
{ ... }:

{
  imports = [
    ./base.nix
    ./desktop.nix
  ];
}
