# nixarr media server stack profile
{ inputs, lib, ... }:

{
  imports = [
    inputs.nixarr.nixosModules.default
  ];

  nixarr = {
    enable = true;
    mediaDir = "/data/media";
    stateDir = "/data/media/.state/nixarr";

    # Enable Jellyfin and the Arr apps
    jellyfin.enable = true;
    sonarr.enable = true;
    radarr.enable = true;
    prowlarr.enable = true;

    # Enable Transmission managed by Nixarr
    transmission = {
      enable = true;
      peerPort = 50000;
    };
  };

  # Custom Transmission RPC configuration for LAN access
  services.transmission = {
    openRPCPort = lib.mkForce true; # Force open port 9091 in the firewall, overriding nixarr default
    settings = {
      rpc-bind-address = lib.mkForce "0.0.0.0";
      rpc-port = lib.mkForce 9091;
      rpc-whitelist-enabled = lib.mkForce false; # Allow LAN devices to connect without restrictions
    };
  };
}
