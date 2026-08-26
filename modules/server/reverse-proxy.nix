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
