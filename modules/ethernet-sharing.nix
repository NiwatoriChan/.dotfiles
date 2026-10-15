# Ethernet sharing — lets NetworkManager share this machine's internet over Ethernet
# ("Shared to other computers" / ipv4.method=shared). Import per-host.
{ ... }:

{
  # Enable IPv4 packet forwarding for internet connection sharing
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  networking.firewall = {
    # Allow DHCP and DNS for NetworkManager connection sharing
    allowedUDPPorts = [ 53 67 68 ];
    allowedTCPPorts = [ 53 ];
    # Avoid dropping forwarded packets via reverse path filter
    checkReversePath = "loose";
  };

  # Tell Quickshell this host supports Ethernet sharing (shows the toggles in the UI)
  home-manager.users.niwatorichan.xdg.configFile."quickshell-host.json".text =
    builtins.toJSON { ethernetSharing = true; };
}
