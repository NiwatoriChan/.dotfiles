# Development profile — development tools like Cursor, Antigravity, and Zed
{ pkgs, pkgs-unstable, ... }:

{
  environment.systemPackages = [
    pkgs-unstable.antigravity
    pkgs.zed-editor
    pkgs-unstable.uv
  ];
}
