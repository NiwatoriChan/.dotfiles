#!/usr/bin/env bash
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

usage() {
  printf 'Usage:\n  %s rebuild [hostname]\n  %s update [hostname]\n  %s sync [hostname]\n  %s check\n  %s clean\n  %s export\n  %s init-secrets\n  %s docs\n' "$0" "$0" "$0" "$0" "$0" "$0" "$0" "$0"
}

if [ "$#" -eq 0 ]; then
  usage
  exit 0
fi

cmd="$1"
shift

case "$cmd" in
  rebuild|update)
    host="${1:-$(hostname)}"
    ;;
  export|clean|check|init-secrets|docs|sync)
    if [ "$#" -ne 0 ]; then
      usage
      exit 1
    fi
    ;;
  help|-h|--help)
    usage
    exit 0
    ;;
  *)
    usage
    exit 1
    ;;
esac

rebuild() {
  sudo nixos-rebuild switch --flake ".#${host}" --impure
}

case "$cmd" in
  rebuild)
    rebuild
    ;;
  update)
    sudo nix flake update
    rebuild
    ;;
  sync)
    echo "Pulling latest dotfiles from GitHub..."
    git pull --rebase
    echo "Dotfiles synced!"
    ;;
  check)
    sudo nix flake check --impure
    ;;
  clean)
    sudo nix-collect-garbage -d
    sudo nix-store --optimise
    ;;
  export)
    out="$(pwd)/config-$(hostname)-$(date +%Y%m%d-%H%M%S).zip"
    sudo find . -type f -print | sudo zip -0 "$out" -@
    sudo chown "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$out" 2>/dev/null || true
    ;;
  init-secrets)
    keyfile="$HOME/.ssh/id_ed25519"
    if [ ! -f "$keyfile" ]; then
      echo "SSH key not found at $keyfile. Generating a new ed25519 key..."
      mkdir -p "$HOME/.ssh"
      ssh-keygen -t ed25519 -N "" -f "$keyfile"
    fi
    pubkey=$(cat "${keyfile}.pub")
    echo "Inserting user SSH public key into secrets/secrets.nix..."
    sed -i "s|user = \".*\"; # USER_SSH_KEY|user = \"$pubkey\"; # USER_SSH_KEY|" secrets/secrets.nix
    echo "Successfully initialized secrets configuration with SSH key!"
    ;;
  docs)
    nix-shell -p python3 --run "python3 docs/build.py"
    ;;
esac
