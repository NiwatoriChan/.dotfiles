{ config, pkgs, ... }:

{
  # Run a lightweight local DNS server
  services.dnsmasq = {
    enable = true;
    settings = {
      # Route jeff.lan and all subdomains (*.jeff.lan) to this server
      address = "/.jeff.lan/192.168.0.10";
      listen-address = "127.0.0.1,192.168.0.10";

      # Forward normal internet traffic to Cloudflare / Google
      server = [ "1.1.1.1" "8.8.8.8" ];
    };
  };

  # Open DNS (port 53) in addition to HTTP/HTTPS
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 80 443 53 ];
}