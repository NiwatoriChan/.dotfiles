{ config, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "jeff.lan" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8082";
        };
      };
      "jellyfin.jeff.lan" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8096";
          proxyWebsockets = true; # Required for Jellyfin playback tracking and websockets
        };
      };
      "sonarr.jeff.lan" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8989";
        };
      };
      "radarr.jeff.lan" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:7878";
        };
      };
      "prowlarr.jeff.lan" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:9696";
        };
      };
      "transmission.jeff.lan" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:9091";
        };
      };
    };
  };

  # Open HTTP and HTTPS ports in the firewall
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
