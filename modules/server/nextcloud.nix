# Nextcloud server configuration backed by PostgreSQL and Redis
{ config, pkgs, lib, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
    hostName = "nextcloud.jeff.lan";

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
        "jeff.lan"
      ];
      default_phone_region = "CA";
      log_type = "file";
      maintenance_window_start = 1; # 1 AM UTC
    };

    maxUploadSize = "16G";
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
    requires = [ "nextcloud-admin-pass-init.service" ];
    after = [ "nextcloud-admin-pass-init.service" ];
  };
}
