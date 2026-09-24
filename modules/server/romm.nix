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

  # 2. Podman network for isolated inter-container communication
  systemd.services.podman-network-romm = {
    description = "Create Podman network for RomM";
    wantedBy = [ "multi-user.target" ];
    before = [ "podman-romm-db.service" "podman-romm.service" ];
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman network create --ignore romm-net";
    };
  };

  # 3. Generate secret keys and environment files if missing
  systemd.services.romm-env-init = {
    description = "Initialize RomM environment and secret keys";
    wantedBy = [ "multi-user.target" ];
    before = [ "podman-romm-db.service" "podman-romm.service" ];
    path = with pkgs; [ coreutils openssl podman gnused ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      mkdir -p ${rommStateDir}

      ${pkgs.podman}/bin/podman network create --ignore romm-net

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
DB_HOST=romm-db
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
      else
        sed -i 's/^DB_HOST=.*/DB_HOST=romm-db/' "${envFile}"
      fi
    '';
  };

  # 4. Containers configuration
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
          "--network=romm-net"
          "--network-alias=romm-db"
        ];
      };

      romm = {
        image = "rommapp/romm:latest";
        autoStart = true;
        dependsOn = [ "romm-db" ];
        environmentFiles = [ envFile ];
        ports = [
          "${toString rommPort}:8080"
        ];
        volumes = [
          "${rommStateDir}/resources:/romm/resources"
          "${rommStateDir}/redis-data:/redis-data"
          "${rommStateDir}/assets:/romm/assets"
          "${rommStateDir}/config:/romm/config"
          "${romsDir}:/romm/library"
        ];
        extraOptions = [
          "--network=romm-net"
          "--network-alias=romm"
        ];
      };
    };
  };

  # 5. Storage & initialization systemd unit dependencies
  systemd.services.podman-romm-db = {
    after = [ "mnt-exp6.mount" "romm-env-init.service" "podman-network-romm.service" ];
    wants = [ "mnt-exp6.mount" "romm-env-init.service" "podman-network-romm.service" ];
    requires = [ "mnt-exp6.mount" "romm-env-init.service" "podman-network-romm.service" ];
    unitConfig = {
      RequiresMountsFor = [ "/mnt/exp6" rommStateDir ];
    };
  };

  systemd.services.podman-romm = {
    after = [ "mnt-exp6.mount" "romm-env-init.service" "podman-network-romm.service" "podman-romm-db.service" ];
    wants = [ "mnt-exp6.mount" "romm-env-init.service" "podman-network-romm.service" "podman-romm-db.service" ];
    requires = [ "mnt-exp6.mount" "romm-env-init.service" "podman-network-romm.service" "podman-romm-db.service" ];
    serviceConfig = {
      RestartSec = "5s";
    };
    unitConfig = {
      RequiresMountsFor = [ "/mnt/exp6" rommStateDir ];
    };
  };

  # 6. Firewall rule for direct LAN access
  networking.firewall.allowedTCPPorts = [ rommPort ];
}
