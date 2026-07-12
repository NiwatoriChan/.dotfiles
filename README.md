# ❄️ NiwatoriChan's NixOS Dotfiles

A modular, unified, and declarative NixOS flake configuration managing multiple hosts (desktops & headless servers) with customized system profiles and Home Manager configurations.

---

## 🖥️ Host Systems

| Host | Device / Type | Hardware Specifications | Environment | System Config | User Config |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **🍗 PwPoulet** | Primary Desktop | Ryzen 9 3900X + Radeon RX 6750 XT | KDE Plasma 6 | [`hosts/pwpoulet`](./hosts/pwpoulet) | [`home/pwpoulet.nix`](./home/pwpoulet.nix) |
| **🦖 Savage** | Steam Deck LCD | Custom AMD APU + RDNA 2 GPU | Steam Deck Game Mode / Plasma | [`hosts/savage`](./hosts/savage) | [`home/savage.nix`](./home/savage.nix) |
| **🥔 PotatoMonster** | Laptop (Inspiron 7559) | Intel i7 + NVIDIA GTX 960M | MangoWM | [`hosts/potatomonster`](./hosts/potatomonster) | [`home/potatomonster.nix`](./home/potatomonster.nix) |
| **🍠 PetitePatate** *EXPERIMENTAL* | Laptop (Pinebook Pro) | Rockchip RK3399 (OC 2.08GHz) + Mali | Hyprland | [`hosts/petitepatate`](./hosts/petitepatate) | [`home/petitepatate.nix`](./home/petitepatate.nix) |
| **🦙 jeff** *EXPERIMENTAL* | Headless Server | Ryzen 5 1600X + GTX 1070 | Headless CLI / Nixarr | [`hosts/jeff`](./hosts/jeff) | [`home/jeff.nix`](./home/jeff.nix) |

---

## 📦 Configuration Modules

The system uses unified module blocks under `modules/` to manage target packages and environments:

- **`hyprland.nix` / `mangowm.nix` / `kde.nix`**: Graphical environment declarations.
- **`gaming.nix`**: Dedicated gaming packages (Steam, Lutris, Heroic Games Launcher).
- **`jovian-deck.nix` / `jovian-amd.nix`**: Steam Deck / Jovian compatibility layers.
- **`server/`**: A segregated headless server stack including:
  - **Samba** (`samba.nix`): Restricted file sharing for the `niwatorichan` user.
  - **Nixarr** (`nixarr.nix`): Full declarative media stack (Jellyfin, Sonarr, Radarr, Prowlarr, Transmission) with RPC LAN overrides.

---

## 📂 Repository Layout

```text
.dotfiles/
├── flake.nix             # Flake configurations and inputs entrypoint
├── add-caches.sh         # Helper script to bootstrap binary caches
├── modules/              # Unified system + user modules (Gaming, Jovian, Hyprland, KDE, Server)
├── hosts/                # Host-specific settings & hardware profiles
│   ├── common/           # Shared base packages, CLI tools, shell, and configs
│   ├── potatomonster/    # PotatoMonster system configuration
│   ├── pwpoulet/         # PwPoulet system configuration
│   ├── savage/           # Savage (Steam Deck LCD) system configuration
│   ├── jeff/             # Headless server (jeff) system configuration
│   └── petitepatate/     # PetitePatate (Pinebook Pro) configuration
└── home/                 # User-specific Home Manager configurations
    ├── common/           # Shared zsh, git, and baseline configs
    ├── savage.nix        # Savage user environment configuration
    └── config/           # App configuration files (waybar, hypr, etc.)
```

---

## 🔐 Secrets Management

Secrets are managed using **[Agenix](https://github.com/ryantm/agenix)**, which encrypts files using SSH public keys.

### Excluded Secrets Directory
The `/secrets` directory is excluded from Git to prevent tracking raw temporary files or unencrypted files. However, `.age` encrypted files within it are fully safe to commit to version control if you explicitly override/force add them, or you can manage secrets locally.

### Setup and Usage

1. **Define Keys**: Add your SSH public keys (user and system keys) to the [`secrets/secrets.nix`](./secrets/secrets.nix) file.
2. **Create/Edit Secrets**:
   To create or edit a secret file (e.g. `secrets/example-secret.age`):
   ```bash
   nix run github:ryantm/agenix -- -e secrets/example-secret.age
   ```
   *(Ensure you have your SSH private key loaded/accessible to decrypt it next time).*
3. **Reference Secrets**:
   Define the secret in your NixOS configuration (e.g. in a module):
   ```nix
   age.secrets.my-secret.file = ../../secrets/my-secret.age;
   ```
   Agenix will automatically decrypt the file to `/run/agenix/my-secret` on boot with appropriate permissions.

---

## 🚀 Rebuilding & Management

A helper script `./nu` is included at the root of the repository to manage updates, rebuilds, and configuration backups:

### Initializing Secrets Key
To automatically generate a user SSH key if missing and write the public key into the secrets configuration:
```bash
./nu init-secrets
```

### Rebuilding a Host
To rebuild and switch your system configuration (defaults to the current hostname if omitted):
```bash
./nu rebuild [hostname]
```

### Updating Flake Inputs
To update your flake inputs:
```bash
./nu update
```

### Syncing Config from GitHub
To pull and rebase the latest configuration changes:
```bash
./nu sync
```

### Sync, Update, and Rebuild (SUR)
To execute sync, update inputs, and rebuild the host system in one command:
```bash
./nu sur [hostname]
```

### Exporting Configuration
To create a zip archive backup of your current dotfiles config:
```bash
./nu export
```

### Storage Cleanup
To delete old generation symlinks, collect garbage, and optimize the Nix store:
```bash
./nu clean
```

### Verification
Verify all system configurations evaluate and compile successfully before rebuilding:
```bash
./nu check
```

### Bootstrapping Binary Caches
On a fresh system installation, build time can be significantly reduced by registering target binary caches first:
```bash
./nu init
```

### Building Documentation
To build the documentation pages using Python:
```bash
./nu build-docs
```
