{ pkgs, ... }:

{
  # Add your user to transmission's group
  users.users.niwatorichan.extraGroups = [ "transmission" ];

  services.transmission = {
    enable = true;
    openRPCPort = true;
    openPeerPorts = true;

    settings = {
      rpc-bind-address = "0.0.0.0";
      rpc-port = 9091;
      rpc-whitelist-enabled = true;
      rpc-whitelist = "127.0.0.1,192.168.0.*";
      rpc-host-whitelist-enabled = false;

      download-dir = "/mnt/torrent/Download/complete";
      incomplete-dir = "/mnt/torrent/Download/incomplete";
      incomplete-dir-enabled = true;
      watch-dir = "/mnt/torrent/Watch";
      watch-dir-enabled = true;

      # 2 (decimal) = 002 (octal): creates files as 664 (rw-rw-r--) and dirs as 775 (rwxrwxr-x)
      umask = 2;
    };
  };

  # Optional: Declaratively create and enforce directory permissions on boot
  systemd.tmpfiles.rules = [
    # 1. Create the directories if they don't exist
    "d /mnt/torrent 2775 transmission transmission -"
    "d /mnt/torrent/Download 2775 transmission transmission -"
    "d /mnt/torrent/Download/complete 2775 transmission transmission -"
    "d /mnt/torrent/Download/incomplete 2775 transmission transmission -"
    "d /mnt/torrent/Watch 2775 transmission transmission -"

    # 2. Recursively ensure ownership & base permissions (2775) across the entire tree
    "Z /mnt/torrent 2775 transmission transmission -"

    # 3. Recursively set standard and default (inherited) ACLs for niwatorichan & transmission
    "A+ /mnt/torrent - - - - user:niwatorichan:rwx,group:transmission:rwx,default:user:niwatorichan:rwx,default:group:transmission:rwx"
  ];
}