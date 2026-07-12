#!/usr/bin/env bash
set -euo pipefail

# This script creates a minimal flake and builds the minimal system configuration
# to populate and initialize the binary caches.

echo "Detecting host architecture..."
arch=$(uname -m)
case "$arch" in
  x86_64)
    system="x86_64-linux"
    ;;
  aarch64)
    system="aarch64-linux"
    ;;
  *)
    system="x86_64-linux"
    ;;
esac
echo "Target system architecture: $system"

echo "Creating temporary minimal NixOS flake..."
TEMP_DIR=$(mktemp -d -t nix-minimal-flake-XXXXXX)
# Ensure cleanup on exit
trap 'rm -rf "$TEMP_DIR"' EXIT

# Detect existing hardware configuration or fallback
if [ -f /etc/nixos/hardware-configuration.nix ]; then
  echo "Copying /etc/nixos/hardware-configuration.nix..."
  cp /etc/nixos/hardware-configuration.nix "$TEMP_DIR/"
  IMPORT_HW="./hardware-configuration.nix"
else
  echo "No hardware configuration found, generating basic fallback..."
  cat << 'EOF' > "$TEMP_DIR/hardware-configuration.nix"
{ modulesPath, ... }: {
  imports = [ (modulesPath + "/profiles/minimal.nix") ];
  fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
  boot.loader.grub.device = "nodev";
}
EOF
  IMPORT_HW="./hardware-configuration.nix"
fi

cat << EOF > "$TEMP_DIR/flake.nix"
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  nixConfig = {
    extra-substituters = [
      "https://attic.xuyh0120.win/lantian"
      "https://jovian.cachix.org"
      "https://nyx-cache.chaotic.cx"
    ];
    extra-trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "jovian.cachix.org-1:8Vq4Txku6VZIRhYrHYki3Ab9XHJRoWmdYqMqj4rB/Uc="
      "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
    ];
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.minimal = nixpkgs.lib.nixosSystem {
      system = "$system";
      modules = [
        $IMPORT_HW
        ({ pkgs, ... }: {
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;

          nix.settings.experimental-features = [ "nix-command" "flakes" ];

          # Declare cache settings
          nix.settings.extra-substituters = [
            "https://attic.xuyh0120.win/lantian"
            "https://jovian.cachix.org"
            "https://nyx-cache.chaotic.cx"
          ];
          nix.settings.extra-trusted-public-keys = [
            "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
            "jovian.cachix.org-1:8Vq4Txku6VZIRhYrHYki3Ab9XHJRoWmdYqMqj4rB/Uc="
            "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
          ];

          system.stateVersion = "26.05";
        })
      ];
    };
  };
}
EOF

echo "Building the minimal system to register the binary caches..."
sudo nixos-rebuild build --flake "$TEMP_DIR#minimal" --impure --accept-flake-config

echo "Minimal system successfully built!"
echo "The binary caches have been accepted and cached. You can now build/switch to your full system configuration."
