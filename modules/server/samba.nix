# Samba file sharing configuration with auto-discovery
{ ... }:

{
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "NixOS Samba Server";
        "security" = "user";
        "map to guest" = "bad user";
      };
      private = {
        path = "/srv/samba/private";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "niwatorichan";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };

  # Web Services Discovery Daemon for network neighborhood visibility
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  # Declaratively create the private shared folder on boot
  systemd.tmpfiles.rules = [
    "d /srv/samba/private 0770 niwatorichan users - -"
  ];
}
