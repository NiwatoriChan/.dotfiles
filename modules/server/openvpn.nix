# OpenVPN service configuration
{ pkgs, ... }:

{
  # Enable OpenVPN service.
  # Since openvpn configurations require certificates, keys, and specific network topologies,
  # we provide commented templates for either client or server configurations.
  services.openvpn.servers = {
    # To configure an OpenVPN server, uncomment and adapt the configuration below:
    # server = {
    #   config = ''
    #     port 1194
    #     proto udp
    #     dev tun
    #     ca /etc/openvpn/ca.crt
    #     cert /etc/openvpn/server.crt
    #     key /etc/openvpn/server.key
    #     dh /etc/openvpn/dh.pem
    #     server 10.8.0.0 255.255.255.0
    #     ifconfig-pool-persist ipp.txt
    #     keepalive 10 120
    #     cipher AES-256-GCM
    #     persist-key
    #     persist-tun
    #     status openvpn-status.log
    #     verb 3
    #   '';
    # };

    # To configure an OpenVPN client, uncomment and adapt the configuration below:
    # client = {
    #   config = ''
    #     client
    #     dev tun
    #     proto udp
    #     remote your-vpn-server-ip 1194
    #     resolv-retry infinite
    #     nobind
    #     persist-key
    #     persist-tun
    #     ca /etc/openvpn/ca.crt
    #     cert /etc/openvpn/client.crt
    #     key /etc/openvpn/client.key
    #     remote-cert-tls server
    #     cipher AES-256-GCM
    #     verb 3
    #   '';
    # };
  };

  # Open the default OpenVPN port (1194 UDP) in the firewall
  networking.firewall.allowedUDPPorts = [ 1194 ];
}
