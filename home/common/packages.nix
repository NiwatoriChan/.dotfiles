# Shared user-level packages managed by home-manager
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Add user-level packages here as you migrate things from system packages
    # For now, most packages are still in hosts/common/packages.nix at the system level
    # You can gradually move user apps here over time
  ];
}
