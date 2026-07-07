# NixOS System-Level Configuration

This page outlines the system-level configuration of the dotfiles repo, managed inside the `hosts/` folder. All desktop systems import a set of common settings, services, and packages, then extend them with host-specific hardware and program choices.

---

## ⚙️ Core System Settings

Located in `hosts/common/default.nix`, these are the system-wide baselines:

- **Bootloader**: Configured to use `systemd-boot` with EFI support (`boot.loader.efi.canTouchEfiVariables = true`).
- **Locales & Timezone**:
  - Timezone: `America/Toronto`
  - Locale: `en_CA.UTF-8`
  - Keymap: French Canadian (`ca`) layout for both virtual console and X11/Wayland servers.
- **Experimental Features**: Enabled `nix-command` and `flakes` by default.
- **AppImage Support**: Enabled via `programs.appimage` with binfmt registrations.
- **Containerization**: Podman is enabled with Docker compatibility (`dockerCompat = true`).

---

## 🛠️ Shared System Packages

Defined in `hosts/common/packages.nix`, these are installed globally on all desktops:

### Applications & Games
- **Browsers**: `Firefox` (declaratively enabled), `Helium` (via custom flake).
- **Communication & Editors**: `Discord`, `Zed Editor`.
- **Gaming Clients**: `Lutris`, `Heroic Games Launcher`, `Steam` (enabled via `programs.steam.enable = true`).

### CLI Utilities & Theming
- **Utilities**: `vim`, `wget`, `git`, `curl`, `jq`, `bat`, `gnumake`, `fastfetch`.
- **Terminals**: `kitty`, `alacritty`.
- **Theming**: `papirus-icon-theme`, `sddm-astronaut`.
- **Special Helper**: `antigravity`.

---

## 🔌 System Services

Defined in `hosts/common/services.nix`, the core background services include:

### 🖥️ Display Manager (SDDM)
We use SDDM in Wayland mode using the elegant Astronaut theme:
- Theme: `sddm-astronaut-theme` (provided by `sddm-astronaut` packages)
- Autologin/Display settings are customized through it.

### 🎵 Audio (PipeWire)
PulseAudio is disabled in favor of PipeWire:
- RTKit is enabled for real-time scheduling.
- Support enabled for `alsa`, `alsa.support32Bit`, and `pulse` emulation.

### 📶 Connectivity & Hardware
- **Bluetooth**: Enabled with power-on-boot support (`hardware.bluetooth.powerOnBoot = true`).
- **Printing**: CUPS is enabled via `services.printing.enable = true`.

### 📦 Flatpak Integration
Flatpak is enabled, and a systemd service automatically registers the Flathub repository on boot:
```nix
systemd.services.flatpak-repo = {
  wantedBy = [ "multi-user.target" ];
  path = [ pkgs.flatpak ];
  script = ''
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  '';
};
```
---

## 🖥️ Host Modules

Specific system host modules override or add system services:

### 1. PotatoMonster (`hosts/potatomonster`)
- **Programs**: MangoWM (`programs.mango.enable = true`).
- **Packages**: `alsa-utils`, `brightnessctl` (for managing volume and backlight).
- **Hardware**: Imports `hosts/potatomonster/hardware.nix` and system-specific hardware parameters.

### 2. PwPoulet (`hosts/pwpoulet`)
- **Kernel**: Configured to use the performance-optimized **CachyOS kernel** (\`boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest\`).
- **Services**: KDE Plasma 6 (\`services.desktopManager.plasma6.enable = true\`). Configured modularly via \`modules/kde.nix\` to use an overlay replacing \`kdePackages\` with the latest unstable releases (\`pkgs-unstable.kdePackages\`).
- **Packages**: Dolphin (\`kdePackages.dolphin\`) and Qt Multimedia support (\`kdePackages.qtmultimedia\`).
- **Hardware**: Configured with standard desktop x86_64 hardware modules.

### 3. PetitePatate (`hosts/petitepatate`)
- **Device/Architecture**: Pinebook Pro (aarch64 ARM64).
- **Kernel/Hardware**: Integrates custom NixOS hardware modules alongside device tree overlay overrides for CPU/GPU overclocking (up to 2.08GHz) and stable undervolting.
- **Graphical Environment**: Enables and configures Hyprland (`modules/hyprland.nix`).

### 4. jeff (`hosts/jeff`)
- **Type**: Headless Server.
- **Services**: Imports core server modules (`modules/server/default.nix`) enabling declarative Samba storage sharing, OpenVPN tunneling, the Homepage portal, and the Nixarr stack.

---

## 🌐 Server & Network Services

Unified server services are managed modularly under `modules/server/`:

- **Homepage Dashboard** (`homepage.nix`): Launches a system dashboard on port `8082`. It displays server resources and custom service widgets for network apps.
- **OpenVPN Client** (`openvpn.nix`): Manages tunnel configuration to secure networks using credential keys.
- **Samba Sharing** (`samba.nix`): Configures secure SMB folder sharing across the local network for system users.
- **Nixarr Media Stack** (`nixarr.nix`): Automates Jellyfin, Sonarr, Radarr, Prowlarr, and Transmission with specialized local network RPC overrides (refer to [Nixarr Stack](#nixarr) for dedicated details).

---

## 🔐 Secrets Management (Agenix)

System secrets (such as API keys, passwords, and server credentials) are encrypted and managed using **[Agenix](https://github.com/ryantm/agenix)**:

- **Git Ignored Store**: The local `/secrets` directory is ignored by Git to store raw keys and unencrypted credentials safely.
- **Encrypted Store**: Encrypted secret definitions (ending in `.age`) reside in the root `secrets/` directory and are safe to commit.
- **Authentication**: Decryption relies on system or user SSH keys defined in `secrets/secrets.nix`.

### Usage Workflow

1. **Initialize SSH Keys**: Run the helper command to map your public key to the secrets configurations:
   ```bash
   ./nu init-secrets
   ```
2. **Create/Edit Secret**: Use the agenix CLI runner to open or update a secure secret file:
   ```bash
   nix run github:ryantm/agenix -- -e secrets/my-secret.age
   ```
3. **Reference in Configuration**: Map the encrypted file to your NixOS environment:
   ```nix
   age.secrets.my-secret.file = ../../secrets/my-secret.age;
   ```
   At boot, Agenix decrypts the files and exposes them securely to processes at `/run/agenix/my-secret`.
