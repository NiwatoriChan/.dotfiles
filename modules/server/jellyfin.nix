# Jellyfin Media Server configuration
{ config, pkgs, lib, ... }:

let
  mediaBaseDir = "/mnt/exp6/EXP6/MEDIAX/Videos";
in
{
  # Add your user to jellyfin's group
  users.users.niwatorichan.extraGroups = [ "jellyfin" ];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # Automatic library registration for each video folder (excluding zzISSUE and Homemade)
  systemd.services.jellyfin = {
    after = [ "mnt-exp6.mount" ];
    wants = [ "mnt-exp6.mount" ];

    preStart = ''
      MEDIA_DIR="${mediaBaseDir}"
      ROOT_DEFAULT="/var/lib/jellyfin/root/default"

      mkdir -p "$ROOT_DEFAULT"

      if [ -d "$MEDIA_DIR" ]; then
        for folder in "$MEDIA_DIR"/*/; do
          [ -d "$folder" ] || continue
          name=$(basename "$folder")

          # Exclude zzISSUE and Homemade
          if [ "$name" = "zzISSUE" ] || [ "$name" = "Homemade" ]; then
            continue
          fi

          lib_dir="$ROOT_DEFAULT/$name"
          mkdir -p "$lib_dir"

          # Link the media path into Jellyfin's virtual library root
          if [ ! -e "$lib_dir/$name" ]; then
            ln -sfn "$folder" "$lib_dir/$name"
          fi
        done
      fi
    '';
  };

  # Declaratively create and enforce directory permissions and ACLs on boot
  systemd.tmpfiles.rules = [
    # 1. Create the directories if they don't exist
    "d ${mediaBaseDir} 2775 jellyfin jellyfin -"
    "d /var/lib/jellyfin 2775 jellyfin jellyfin -"
    "d /var/lib/jellyfin/root 2775 jellyfin jellyfin -"
    "d /var/lib/jellyfin/root/default 2775 jellyfin jellyfin -"

    # 2. Recursively ensure ownership & base permissions (2775) across the media tree
    "Z ${mediaBaseDir} 2775 jellyfin jellyfin -"

    # 3. Recursively set standard and default (inherited) ACLs for niwatorichan & jellyfin
    "A+ ${mediaBaseDir} - - - - user:niwatorichan:rwx,group:jellyfin:rwx,default:user:niwatorichan:rwx,default:group:jellyfin:rwx"
  ];
}
