# RomM (ROM Manager & Player) container and service configuration
{ config, pkgs, lib, ... }:

let
  rommStateDir = "/var/lib/romm";
  romsDir = "/mnt/exp6/EXP6/ROMs";
  rommPort = 8083;
  envFile = "${rommStateDir}/romm.env";
  dbEnvFile = "${rommStateDir}/db.env";
in
{
  # 1. State directory and library permissions
  systemd.tmpfiles.rules = [
    "d ${rommStateDir} 0750 root root -"
    "d ${rommStateDir}/db 0750 999 999 -"
    "d ${rommStateDir}/resources 0775 1000 1000 -"
    "d ${rommStateDir}/assets 0775 1000 1000 -"
    "d ${rommStateDir}/redis-data 0775 1000 1000 -"
    "d ${rommStateDir}/config 0775 1000 1000 -"
    "d ${romsDir} 2775 niwatorichan users -"
    "Z ${romsDir} 2775 niwatorichan users -"
    "A+ ${romsDir} - - - - user:niwatorichan:rwx,group:users:rwx,default:user:niwatorichan:rwx,default:group:users:rwx"
  ];

  # 2. Generate secret keys and environment files if missing
  systemd.services.romm-env-init = {
    description = "Initialize RomM environment and secret keys";
    wantedBy = [ "multi-user.target" ];
    before = [ "podman-romm-db.service" "podman-romm.service" ];
    path = with pkgs; [ coreutils openssl ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      mkdir -p ${rommStateDir}

      if [ ! -f "${dbEnvFile}" ]; then
        DB_PASSWORD=$(openssl rand -hex 16)
        DB_ROOT_PASSWORD=$(openssl rand -hex 16)
        cat <<EOF > "${dbEnvFile}"
MARIADB_ROOT_PASSWORD=''${DB_ROOT_PASSWORD}
MARIADB_DATABASE=romm
MARIADB_USER=romm-user
MARIADB_PASSWORD=''${DB_PASSWORD}
EOF
        chmod 0600 "${dbEnvFile}"
      fi

      if [ ! -f "${envFile}" ]; then
        source "${dbEnvFile}"
        ROMM_SECRET=$(openssl rand -hex 32)
        cat <<EOF > "${envFile}"
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=romm
DB_USER=romm-user
DB_PASSWD=''${MARIADB_PASSWORD}
ROMM_AUTH_SECRET_KEY=''${ROMM_SECRET}
ROMM_BASE_PATH=/romm
ROMM_BASE_URL=https://romm.jeff.lan
ROMM_PORT=8080
CLIENT_MAX_BODY_SIZE=1000M
HASHEOUS_API_ENABLED=true
SCAN_WORKERS=4
WEB_SERVER_CONCURRENCY=4
EOF
        chmod 0600 "${envFile}"
      fi
    '';
  };

  # 3. Create user-defined podman network 'romm-net' if needed, or run on host network for seamless local binding
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      romm-db = {
        image = "mariadb:11.4";
        autoStart = true;
        environmentFiles = [ dbEnvFile ];
        volumes = [
          "${rommStateDir}/db:/var/lib/mysql"
        ];
        extraOptions = [
          "--net=host"
        ];
      };

      romm = {
        image = "rommapp/romm:latest";
        autoStart = true;
        dependsOn = [ "romm-db" ];
        environmentFiles = [ envFile ];
        ports = [
          "127.0.0.1:${toString rommPort}:8080"
        ];
        volumes = [
          "${rommStateDir}/resources:/romm/resources"
          "${rommStateDir}/redis-data:/redis-data"
          "${rommStateDir}/assets:/romm/assets"
          "${rommStateDir}/config:/romm/config"
          "${romsDir}:/romm/library"
        ];
        extraOptions = [
          "--add-host=host.containers.internal:host-gateway"
        ];
      };
    };
  };

  # 4. Storage & initialization systemd unit dependencies
  systemd.services.podman-romm-db = {
    after = [ "mnt-exp6.mount" "romm-env-init.service" ];
    wants = [ "mnt-exp6.mount" "romm-env-init.service" ];
    requires = [ "mnt-exp6.mount" "romm-env-init.service" ];
    unitConfig = {
      RequiresMountsFor = [ "/mnt/exp6" rommStateDir ];
    };
  };

  systemd.services.podman-romm = {
    after = [ "mnt-exp6.mount" "romm-env-init.service" "podman-romm-db.service" ];
    wants = [ "mnt-exp6.mount" "romm-env-init.service" "podman-romm-db.service" ];
    requires = [ "mnt-exp6.mount" "romm-env-init.service" "podman-romm-db.service" ];
    unitConfig = {
      RequiresMountsFor = [ "/mnt/exp6" rommStateDir ];
    };
  };
}
