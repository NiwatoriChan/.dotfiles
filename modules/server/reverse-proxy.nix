{ config, pkgs, lib, ... }:

let
  sslCertDir = "/mnt/partage/ssl";
  sslCert = "${sslCertDir}/cert.pem";
  sslKey = "${sslCertDir}/key.pem";
in
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      # Plain HTTP helper for downloading the Root CA certificate to mobile devices
      "cert-download" = {
        listen = [
          { addr = "0.0.0.0"; port = 8080; }
          { addr = "[::0]"; port = 8080; }
        ];
        locations."/" = {
          alias = "${sslCertDir}/";
          extraConfig = ''
            types {
              application/x-x509-ca-cert crt pem;
            }
            default_type application/x-x509-ca-cert;
            add_header Content-Disposition 'attachment; filename="ca.crt"';
          '';
        };
        locations."= /ca.crt" = {
          alias = "${sslCertDir}/ca.crt";
          extraConfig = ''
            types {
              application/x-x509-ca-cert crt pem;
            }
            default_type application/x-x509-ca-cert;
            add_header Content-Disposition 'attachment; filename="ca.crt"';
          '';
        };
      };

      "jeff.lan" = {
        serverAliases = [ "192.168.0.10" ];
        forceSSL = true;
        sslCertificate = sslCert;
        sslCertificateKey = sslKey;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8082";
        };
      };
      "jellyfin.jeff.lan" = {
        forceSSL = true;
        sslCertificate = sslCert;
        sslCertificateKey = sslKey;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8096";
          proxyWebsockets = true;
        };
      };
      "transmission.jeff.lan" = {
        forceSSL = true;
        sslCertificate = sslCert;
        sslCertificateKey = sslKey;
        locations."/" = {
          proxyPass = "http://127.0.0.1:9091";
        };
      };
    };
  };

  # Automatically provision a local Root CA and wildcard SSL certificate on Partage drive if missing
  systemd.services.nginx-ssl-certs-init = {
    description = "Initialize wildcard SSL certificates on Partage drive";
    wantedBy = [ "multi-user.target" ];
    before = [ "nginx.service" ];
    after = [ "mnt-partage.mount" ];
    wants = [ "mnt-partage.mount" ];
    requires = [ "mnt-partage.mount" ];
    unitConfig = {
      RequiresMountsFor = [ "/mnt/partage" ];
    };
    path = with pkgs; [ openssl coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      mkdir -p ${sslCertDir}
      cd ${sslCertDir}

      # 1. Generate local Root CA if not present
      if [ ! -f ca.crt ] || [ ! -f ca.key ]; then
        echo "Generating local Certificate Authority (CA)..."
        openssl req -x509 -new -nodes -newkey rsa:4096 \
          -keyout ca.key -out ca.crt -days 3650 \
          -subj "/C=CA/ST=QC/O=Jeff HomeLab/CN=Jeff Local Root CA"
        chmod 0600 ca.key
      fi

      # 2. Generate Server Wildcard Certificate & Key if not present or missing niwatorichan.ddns.net
      if [ ! -f cert.pem ] || [ ! -f key.pem ] || ! openssl x509 -in cert.pem -noout -text 2>/dev/null | grep -q "niwatorichan.ddns.net"; then
        echo "Generating wildcard server certificate for *.jeff.lan, jeff.lan, and niwatorichan.ddns.net..."
        openssl req -new -newkey rsa:2048 -nodes \
          -keyout key.pem -out cert.csr \
          -subj "/C=CA/ST=QC/O=Jeff HomeLab/CN=jeff.lan"

        cat << 'EOF' > ext.cnf
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = jeff.lan
DNS.2 = *.jeff.lan
DNS.3 = localhost
DNS.4 = niwatorichan.ddns.net
DNS.5 = *.niwatorichan.ddns.net
IP.1 = 192.168.0.10
IP.2 = 127.0.0.1
IP.3 = 10.8.0.1
EOF

        openssl x509 -req -in cert.csr \
          -CA ca.crt -CAkey ca.key -CAcreateserial \
          -out cert-raw.pem -days 1825 \
          -extfile ext.cnf

        # Bundle server cert with CA so clients receive the complete chain
        cat cert-raw.pem ca.crt > cert.pem
        rm -f cert-raw.pem ext.cnf cert.csr

        chmod 0640 key.pem
        chmod 0644 cert.pem
        chown root:nginx key.pem cert.pem ca.crt ca.key 2>/dev/null || true
      fi
    '';
  };

  # Ensure Nginx waits for the storage mount and certificate generation
  systemd.services.nginx = {
    after = [ "mnt-partage.mount" "nginx-ssl-certs-init.service" ];
    wants = [ "mnt-partage.mount" "nginx-ssl-certs-init.service" ];
    requires = [ "mnt-partage.mount" "nginx-ssl-certs-init.service" ];
    unitConfig = {
      RequiresMountsFor = [ "/mnt/partage" ];
    };
  };

  # Open HTTP and HTTPS ports in the firewall
  networking.firewall.allowedTCPPorts = [ 80 443 8080 ];
}
