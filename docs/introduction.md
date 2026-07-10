# Welcome to the Dotfiles Documentation

This documentation details the system and environment configurations for **niwatorichan**'s NixOS machines. The configuration is fully declarative, flake-based, and modularized.

---

## 📂 Repository Structure

The configuration files are organized as follows:

```text
.dotfiles/
├── flake.nix             # System configurations and inputs entry point
├── flake.lock            # Lock file for Nix inputs pinning versions
├── docs/                 # Documentation (this portal)
│   ├── index.html        # Interactive documentation viewer
│   └── *.md              # Section-specific markdown documents
├── modules/              # Unified system + user modules (Hyprland, MangoWM, KDE, Server, Gaming)
├── hosts/                # Machine-specific NixOS configurations
│   ├── common/           # Shared system settings, packages, and services
│   ├── potatomonster/    # Config for PotatoMonster (MangoWM system)
│   ├── pwpoulet/         # Config for PwPoulet (KDE Plasma 6 system)
│   ├── savage/           # Config for Savage (Steam Deck LCD system)
│   ├── jeff/             # Config for jeff (headless server profile)
│   └── petitepatate/     # Config for PetitePatate (Pinebook Pro ARM64 system)
├── home/                 # User-specific Home Manager configurations
│   ├── common/           # Shared user packages, shell (zsh/p10k), and git
│   ├── config/           # User configuration files (doom, waybar, hypr, mango, etc.)
│   ├── potatomonster.nix # User environment for PotatoMonster (MangoWM configs)
│   ├── pwpoulet.nix      # User environment for PwPoulet (KDE wrapper)
│   ├── savage.nix        # User environment for Savage (Steam Deck common configs)
│   └── petitepatate.nix  # User environment for PetitePatate (ARM64 configs)
```

---

## 🖥️ System Profiles

The configurations define four target machines and one headless server:

| Machine Name | Device Type | Window Manager / DE | NixOS Host Config | Home Manager Profile |
| :--- | :--- | :--- | :--- | :--- |
| **PotatoMonster** | Laptop (x86_64) | MangoWM / Hyprland | `hosts/potatomonster` | `home/potatomonster.nix` |
| **PwPoulet** | Desktop (x86_64) | KDE Plasma 6 (Unstable) | `hosts/pwpoulet` | `home/pwpoulet.nix` |
| **Savage** | Steam Deck (x86_64) | Steam Deck Game Mode / KDE Plasma | `hosts/savage` | `home/savage.nix` |
| **PetitePatate** | Pinebook Pro (aarch64) | Hyprland | `hosts/petitepatate` | `home/petitepatate.nix` |
| **jeff** | Headless Server (x86_64) | *None (CLI)* | `hosts/jeff` | `home/jeff.nix` |

---

## 🚀 Helper CLI Tool (`./nu`)

A helper script `./nu` is included at the root of the repository to manage updates, rebuilds, configuration backups, and secrets initialization:

### Rebuilding NixOS
To rebuild and apply system configuration switch (defaults to current hostname if omitted):
```bash
./nu rebuild [hostname]
```

### Updating Flake Inputs
To update your flake inputs:
```bash
./nu update
```

### Syncing Configuration
To pull the latest changes from the GitHub remote repository:
```bash
./nu sync
```

### Sync, Update, and Rebuild (SUR)
To run a full sync, update flake inputs, and rebuild the system in one command:
```bash
./nu sur [hostname]
```

### Initializing Secrets
To automatically generate a user SSH key if missing and write the public key into the secrets configuration:
```bash
./nu init-secrets
```

### Rebuilding Documentation
To compile markdown files into the `docs/index.html` portal:
```bash
./nu docs
```

### Storage Cleanup
To delete old generation symlinks, collect garbage, and optimize the Nix store:
```bash
./nu clean
```
