# No-IP Dynamic DNS Update Client (noip-duc) service
{ config, pkgs, lib, ... }:

{
  systemd.services.noip-duc = {
    description = "No-IP Dynamic DNS Update Client (niwatorichan.ddns.net)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "60s";
      Environment = [
        "NOIP_HOSTNAMES=niwatorichan.ddns.net"
        "NOIP_CHECK_INTERVAL=5m"
      ];
      EnvironmentFile = "-/etc/noip.env";
      ExecCondition = "${pkgs.bash}/bin/bash -c 'test -s /etc/noip.env || { echo \"/etc/noip.env is missing or empty. Please populate it with NOIP_USERNAME and NOIP_PASSWORD.\"; exit 1; }'";
      ExecStart = "${pkgs.noip}/bin/noip-duc";
    };
  };
}
