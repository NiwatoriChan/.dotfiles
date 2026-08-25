{ config, pkgs, lib, ... }:

let
  serverName = "vpnServer";
  clientName = "niwatorichan";
in
{
  # 1. OpenVPN Server
  services.openvpn.servers.${serverName} = {
    autoStart = true;
    config = ''
      port 1194
      proto udp
      dev tun0
      ca /var/lib/openvpn/ca.crt
      cert /var/lib/openvpn/server.crt
      key /var/lib/openvpn/server.key
      dh /var/lib/openvpn/dh.pem
      tls-auth /var/lib/openvpn/ta.key 0

      server 10.8.0.0 255.255.255.0
      ifconfig-pool-persist /var/lib/openvpn/ipp.txt

      push "redirect-gateway def1 bypass-dhcp"
      push "dhcp-option DNS 1.1.1.1"
      push "dhcp-option DNS 8.8.8.8"

      keepalive 10 120
      cipher AES-256-GCM
      auth SHA256
      persist-key
      persist-tun
      status /var/log/openvpn-status.log
      verb 3
    '';
  };

  # 2. Guarantee OpenVPN waits for PKI generation before starting
  systemd.services."openvpn-${serverName}" = {
    requires = [ "openvpn-pki-init.service" ];
    after = [ "openvpn-pki-init.service" ];
  };

  # 3. Deterministic PKI & .ovpn Generation with OpenSSL
  systemd.services.openvpn-pki-init = {
    description = "Initialize OpenVPN PKI and Generate Client Profile";
    wantedBy = [ "multi-user.target" ];
    before = [ "openvpn-${serverName}.service" ];
    path = with pkgs; [ openssl openvpn bash coreutils curl ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      mkdir -p /var/lib/openvpn
      cd /var/lib/openvpn

      # --- Generate Certificates if CA doesn't exist ---
      if [ ! -f /var/lib/openvpn/ca.crt ]; then
        # 1. Certificate Authority (CA)
        openssl req -x509 -new -nodes -newkey rsa:2048 -days 3650 \
          -keyout /var/lib/openvpn/ca.key \
          -out /var/lib/openvpn/ca.crt \
          -subj "/CN=OpenVPN-CA"

        # 2. Server Certificate & Key
        openssl req -new -nodes -newkey rsa:2048 \
          -keyout /var/lib/openvpn/server.key \
          -out /var/lib/openvpn/server.csr \
          -subj "/CN=server"

        openssl x509 -req -in /var/lib/openvpn/server.csr \
          -CA /var/lib/openvpn/ca.crt -CAkey /var/lib/openvpn/ca.key -CAcreateserial \
          -out /var/lib/openvpn/server.crt -days 3650 \
          -extfile <(printf "basicConstraints=CA:FALSE\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth")

        # 3. Client Certificate & Key
        openssl req -new -nodes -newkey rsa:2048 \
          -keyout /var/lib/openvpn/${clientName}.key \
          -out /var/lib/openvpn/${clientName}.csr \
          -subj "/CN=${clientName}"

        openssl x509 -req -in /var/lib/openvpn/${clientName}.csr \
          -CA /var/lib/openvpn/ca.crt -CAkey /var/lib/openvpn/ca.key -CAcreateserial \
          -out /var/lib/openvpn/${clientName}.crt -days 3650 \
          -extfile <(printf "basicConstraints=CA:FALSE\nkeyUsage=digitalSignature\nextendedKeyUsage=clientAuth")

        # 4. Diffie-Hellman & TLS Auth Key
        openssl dhparam -out /var/lib/openvpn/dh.pem 2048
        openvpn --genkey secret /var/lib/openvpn/ta.key

        # Secure private keys
        chmod 600 /var/lib/openvpn/*.key
      fi

      # --- Resolve Server Host / IP ---
      if [ -f /var/lib/openvpn/server-host ]; then
        SERVER_HOST=$(cat /var/lib/openvpn/server-host | tr -d '[:space:]')
      else
        SERVER_HOST=$(curl -s --max-time 5 https://api.ipify.org || curl -s --max-time 5 https://ifconfig.me || echo "127.0.0.1")
      fi

      # --- Generate Standalone .ovpn Profile ---
      OUTPUT_OVPN="/home/${clientName}/${clientName}.ovpn"
      if [ ! -f "$OUTPUT_OVPN" ]; then
        cat <<EOF > "$OUTPUT_OVPN"
client
dev tun
proto udp
remote $SERVER_HOST 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
key-direction 1
verb 3

<ca>
$(cat /var/lib/openvpn/ca.crt)
</ca>

<cert>
$(cat /var/lib/openvpn/${clientName}.crt)
</cert>

<key>
$(cat /var/lib/openvpn/${clientName}.key)
</key>

<tls-auth>
$(cat /var/lib/openvpn/ta.key)
</tls-auth>
EOF
        chown ${clientName}:users "$OUTPUT_OVPN"
        chmod 600 "$OUTPUT_OVPN"
      fi
    '';
  };

  # 4. Firewall & Kernel Forwarding
  networking.firewall.allowedUDPPorts = [ 1194 ];
  boot.kernel.sysctl."net.ipv4.ip_forward" = lib.mkDefault 1;

  # 5. NAT — masquerade VPN clients so they can reach the internet
  networking.nat = {
    enable = true;
    internalInterfaces = [ "tun0" ];
    externalInterface = "eth0";  # ← adjust if your WAN interface differs (e.g. enp0s3, wlan0)
  };
}