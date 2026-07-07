# Gaming system profile — Steam, Lutris, and Heroic
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    lutris
    heroic
  ];

  programs.steam = {
    enable = true;
  };
}
