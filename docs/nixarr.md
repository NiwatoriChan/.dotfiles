# 🎬 Nixarr Media Stack

The **Nixarr** stack is a declarative media server configuration implemented using the `nixarr` NixOS module flake. It consolidates a suite of media management and downloading services into a unified, self-hosted deployment.

The stack is activated globally on the headless server configuration (**jeff**) via the server module entrypoint (`modules/server/default.nix`).

---

## 🏗️ Stack Architecture & Directories

All services in the Nixarr stack share a common storage layout to ensure seamless integration and file-sharing:

- **Media Directory**: `/data/media`  
  This is the root directory where downloaded movies, TV shows, and torrent data are organized.
- **State Directory**: `/data/media/.state/nixarr`  
  This directory persists the internal database, settings, and state of each individual service.

---

## 🔌 Service Catalog & Network Ports

Each service in the stack runs on its default port and is exposed through the host's firewall to allow access across the local area network (LAN).

| Service | Purpose | Port | Firewall Protocol |
| :--- | :--- | :--- | :--- |
| **Jellyfin** | Media streaming, transcribing, and client playback | `8096` | TCP (Allowed) |
| **Sonarr** | Automated TV show finder, organizer, and tracker | `8989` | TCP (Allowed) |
| **Radarr** | Automated movie finder, organizer, and tracker | `7878` | TCP (Allowed) |
| **Prowlarr** | Torrent and Usenet indexer integration manager | `9696` | TCP (Allowed) |
| **Transmission** | Torrent downloader client (RPC interface) | `9091` | TCP (Allowed) |
| **Transmission Peer** | Torrent network peer connection traffic | `50000` | TCP (Managed by Nixarr) |

> [!NOTE]
> All services are registered on the **Homepage** dashboard (`modules/server/homepage.nix`) under the **Media Stack** group for easy management and quick navigation.

---

## ⚙️ Declarative NixOS Configuration

The stack is defined in `modules/server/nixarr.nix` and leverages the `nixarr` flake input.

### Nixarr Module Configuration
The base activation imports the flake input module and defines the state and media paths:
```nix
nixarr = {
  enable = true;
  mediaDir = "/data/media";
  stateDir = "/data/media/.state/nixarr";

  jellyfin.enable = true;
  sonarr.enable = true;
  radarr.enable = true;
  prowlarr.enable = true;

  transmission = {
    enable = true;
    peerPort = 50000;
  };
};
```

### Transmission LAN Override
To facilitate access to Transmission's web interface from other devices on the LAN, the standard Nixarr security restrictions are bypassed via system-level overrides:
```nix
services.transmission = {
  openRPCPort = lib.mkForce true;
  settings = {
    rpc-bind-address = lib.mkForce "0.0.0.0";
    rpc-port = lib.mkForce 9091;
    rpc-whitelist-enabled = lib.mkForce false; # Disable LAN IP restrictions
  };
};
```

> [!WARNING]
> Disabling `rpc-whitelist-enabled` allows any device on the local network to access the Transmission torrent client without authentication unless additional username/password controls are configured.

---

## 🚀 Accessing the Stack

Once the **jeff** host is running and the system is rebuilt, you can access the services:

1. **Via Dashboard**: Open the Server Dashboard at `http://<jeff-ip>:8082` to see status widgets and click direct links.
2. **Direct Connection**: Navigate directly to any of the service URLs:
   - Jellyfin: `http://<jeff-ip>:8096`
   - Sonarr: `http://<jeff-ip>:8989`
   - Radarr: `http://<jeff-ip>:7878`
   - Prowlarr: `http://<jeff-ip>:9696`
   - Transmission: `http://<jeff-ip>:9091`
