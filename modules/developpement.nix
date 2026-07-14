# Development profile — development tools like Cursor, Antigravity, and Zed
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    antigravity
    zed-editor
    code-cursor
  ];
}
