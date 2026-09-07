# Nextcloud server configuration backed by PostgreSQL and Redis
{ config, pkgs, lib, ... }:

let
  sslCertDir = "/mnt/partage/ssl";
  nextcloudDatadir = "/mnt/exp6/EXP6/NextCloud";
  overrideConfigRule = lib.findFirst
    (r: lib.isString r && lib.hasInfix "override.config.php" r)
    ""
    config.systemd.tmpfiles.rules;
  overrideConfigFile = lib.last (lib.splitString " " overrideConfigRule);
in
{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
    hostName = "nextcloud.jeff.lan";
    https = true;

    # Local PostgreSQL database management
    database.createLocally = true;

    # Local Redis for memory and file-locking cache
    configureRedis = true;

    # App management
    appstoreEnable = true;
    autoUpdateApps.enable = true;

    # Core configuration
    config = {
      dbtype = "pgsql";
      adminuser = "admin";
      adminpassFile = "/etc/nextcloud-admin-pass";
    };

    settings = {
      trusted_domains = [
        "nextcloud.jeff.lan"
        "192.168.0.10"
        "10.8.0.1"
        "jeff.lan"
        "niwatorichan.ddns.net"
      ];
      default_phone_region = "CA";
      log_type = "file";
      maintenance_window_start = 1; # 1 AM UTC
      overwriteprotocol = "https";
    };

    datadir = nextcloudDatadir;
    maxUploadSize = "16G";
  };

  # Configure Nginx virtual host with SSL
  services.nginx.virtualHosts."nextcloud.jeff.lan" = {
    forceSSL = true;
    serverAliases = [
      "192.168.0.10"
      "10.8.0.1"
      "niwatorichan.ddns.net"
    ];
    sslCertificate = "${sslCertDir}/cert.pem";
    sslCertificateKey = "${sslCertDir}/key.pem";
  };

  # Allow niwatorichan to access Nextcloud folders and run occ
  users.users.niwatorichan.extraGroups = [ "nextcloud" ];

  # Safe migration service: copies existing Nextcloud files to RAID5 if not already present
  systemd.services.nextcloud-migrate-datadir = {
    description = "Migrate Nextcloud data directory to RAID5 (/mnt/exp6/EXP6/NextCloud)";
    wantedBy = [ "multi-user.target" ];
    before = [ "nextcloud-setup.service" "phpfpm-nextcloud.service" ];
    after = [ "mnt-exp6.mount" ];
    wants = [ "mnt-exp6.mount" ];
    requires = [ "mnt-exp6.mount" ];
    unitConfig = {
      RequiresMountsFor = [ "/mnt/exp6" ];
    };
    path = with pkgs; [ coreutils gnused rsync ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      TARGET_DIR="${nextcloudDatadir}"
      SOURCE_DIR="/var/lib/nextcloud"

      mkdir -p "$TARGET_DIR"

      # If source data exists and target data does not exist or is empty, copy everything over
      if [ -d "$SOURCE_DIR/data" ]; then
        if [ ! -d "$TARGET_DIR/data" ] || [ -z "$(ls -A "$TARGET_DIR/data" 2>/dev/null)" ]; then
          echo "Copying existing Nextcloud files from $SOURCE_DIR to $TARGET_DIR..."
          rsync -a --exclude="override.config.php" "$SOURCE_DIR/" "$TARGET_DIR/"

          # Update datadirectory in config.php to point to RAID 5
          if [ -f "$TARGET_DIR/config/config.php" ]; then
            sed -i "s|'$SOURCE_DIR/data'|'$TARGET_DIR/data'|g" "$TARGET_DIR/config/config.php"
            sed -i "s|\"$SOURCE_DIR/data\"|\"$TARGET_DIR/data\"|g" "$TARGET_DIR/config/config.php"
          fi
        fi
      fi

      # Ensure strict Nextcloud ownership and permissions
      chown -R nextcloud:nextcloud "$TARGET_DIR"
      chmod 0750 "$TARGET_DIR"
      [ -d "$TARGET_DIR/data" ] && chmod -R 0750 "$TARGET_DIR/data" || true
      [ -d "$TARGET_DIR/config" ] && chmod -R 0750 "$TARGET_DIR/config" || true

      # Directly create the declarative override.config.php symlink without systemd-tmpfiles
      mkdir -p "$TARGET_DIR/config"
      ln -sfn "${overrideConfigFile}" "$TARGET_DIR/config/override.config.php"
      chown -h nextcloud:nextcloud "$TARGET_DIR/config/override.config.php"
    '';
  };

  # Ensure the admin password file exists so initial automated setup never fails
  systemd.services.nextcloud-admin-pass-init = {
    description = "Ensure Nextcloud admin password file exists";
    wantedBy = [ "multi-user.target" ];
    before = [ "nextcloud-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -f /etc/nextcloud-admin-pass ] || [ ! -s /etc/nextcloud-admin-pass ]; then
        echo "admin" > /etc/nextcloud-admin-pass
        chmod 0400 /etc/nextcloud-admin-pass
        chown nextcloud:nextcloud /etc/nextcloud-admin-pass 2>/dev/null || true
      fi
    '';
  };

  systemd.services.nextcloud-setup = {
    requires = [ "nextcloud-admin-pass-init.service" "mnt-exp6.mount" "nextcloud-migrate-datadir.service" ];
    after = [ "nextcloud-admin-pass-init.service" "mnt-exp6.mount" "nextcloud-migrate-datadir.service" ];
    unitConfig = {
      RequiresMountsFor = [ "/mnt/exp6" ];
    };
    preStart = ''
      mkdir -p "${nextcloudDatadir}/config"
      ln -sfn "${overrideConfigFile}" "${nextcloudDatadir}/config/override.config.php"
      chown -h nextcloud:nextcloud "${nextcloudDatadir}/config/override.config.php"
    '';
  };

  systemd.services.phpfpm-nextcloud = {
    requires = [ "mnt-exp6.mount" "nextcloud-migrate-datadir.service" ];
    after = [ "mnt-exp6.mount" "nextcloud-migrate-datadir.service" ];
    unitConfig = {
      RequiresMountsFor = [ "/mnt/exp6" ];
    };
    preStart = ''
      mkdir -p "${nextcloudDatadir}/config"
      ln -sfn "${overrideConfigFile}" "${nextcloudDatadir}/config/override.config.php"
      chown -h nextcloud:nextcloud "${nextcloudDatadir}/config/override.config.php"
    '';
  };

  systemd.services.nextcloud-cron = {
    unitConfig = {
      RequiresMountsFor = [ "/mnt/exp6" ];
    };
  };
}
