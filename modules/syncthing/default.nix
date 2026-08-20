# Default entrypoint for syncthing module (desktop GUI profile by default)
{ ... }:

{
  imports = [
    ./syncthing-gui.nix
  ];
}
