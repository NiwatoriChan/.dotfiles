# Jellyfin Media Server configuration
{ config, pkgs, lib, ... }:

let
  mediaBaseDir = "/mnt/exp6/EXP6/MEDIAX/Videos";
in
{
  # Add your user to jellyfin's group, and jellyfin to transmission's group
  users.users.niwatorichan.extraGroups = [ "jellyfin" ];
  users.users.jellyfin.extraGroups = [ "transmission" ];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # Ensure storage mount is ready before Jellyfin starts
  systemd.services.jellyfin = {
    after = [ "mnt-exp6.mount" ];
    wants = [ "mnt-exp6.mount" ];
    requires = [ "mnt-exp6.mount" ];
    unitConfig = {
      RequiresMountsFor = [ "/mnt/exp6" ];
    };

    serviceConfig = {
      # 0002 umask: creates files as 664 and dirs as 775 for seamless shared read/write
      UMask = lib.mkForce "0002";
      StateDirectory = "jellyfin";
    };

    preStart = ''
      # Remove stale preloaded dummy folders from root/default if options.xml is missing
      if [ -d "/var/lib/jellyfin/root/default" ]; then
        for item in /var/lib/jellyfin/root/default/*; do
          [ -e "$item" ] || continue
          if [ -L "$item" ] || [ ! -f "$item/options.xml" ]; then
            rm -rf "$item"
          fi
        done
      fi

      # Ensure /var/lib/jellyfin exists and provide a convenient /var/lib/jellyfin/media shortcut
      mkdir -p /var/lib/jellyfin
      if [ -d "${mediaBaseDir}" ]; then
        ln -sfn "${mediaBaseDir}" /var/lib/jellyfin/media
      fi
    '';
  };

  # Declaratively create and enforce directory permissions and ACLs on boot
  systemd.tmpfiles.rules = [
    # 1. Create the directories if they don't exist
    "d ${mediaBaseDir} 2775 niwatorichan jellyfin -"
    "d /var/lib/jellyfin 0755 jellyfin jellyfin -"

    # 2. Recursively ensure ownership & base permissions (2775) across the media tree
    "Z ${mediaBaseDir} 2775 niwatorichan jellyfin -"

    # 3. Recursively set standard and default (inherited) ACLs for niwatorichan & jellyfin
    "A+ ${mediaBaseDir} - - - - user:niwatorichan:rwx,group:jellyfin:rwx,default:user:niwatorichan:rwx,default:group:jellyfin:rwx"
  ];
}

