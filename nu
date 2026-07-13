#!/usr/bin/env bash
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

usage() {
  printf 'Usage:\n  %s [options] <command> [arguments]\n\n' "$0"
  printf 'Options:\n'
  printf '  -f, --force       Remove any staging / discard local changes\n'
  printf '  -n, --no-flake    Sync all but the flake.lock\n\n'
  printf 'Commands:\n'
  printf '  init                Bootstrap binary caches by running scripts/add-caches.sh\n'
  printf '  rebuild [hostname]  Rebuild and switch the system configuration\n'
  printf '  update              Update Nix flake inputs\n'
  printf '  sync                Pull and rebase latest dotfiles from GitHub\n'
  printf '  sur [hostname]      Sync repo, update flake, and rebuild host\n'
  printf '  check               Verify system configurations compile cleanly\n'
  printf '  clean               Collect garbage and optimize the Nix store\n'
  printf '  export              Export configuration files into a zip backup\n'
  printf '  init-secrets        Initialize secrets configuration and SSH keys\n'
  printf '  build-docs          Build documentation using python3\n'
}

force=false
no_flake=false
args=()

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--force)
      force=true
      shift
      ;;
    -n|--no-flake)
      no_flake=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

if [ "${#args[@]}" -eq 0 ]; then
  usage
  exit 0
fi

cmd="${args[0]}"
subargs=("${args[@]:1}")

case "$cmd" in
  rebuild|sur)
    if [ "${#subargs[@]}" -gt 1 ]; then
      usage
      exit 1
    fi
    host="${subargs[0]:-$(hostname)}"
    ;;
  init|update|sync|export|clean|check|init-secrets|build-docs)
    if [ "${#subargs[@]}" -ne 0 ]; then
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

if [ "$force" = true ]; then
  echo "Removing any staging..."
  git reset
fi

rebuild() {
  sudo nixos-rebuild switch --flake ".#${host}" --impure
}

pull_repo() {
  local has_bak=false
  if [ "$no_flake" = true ] && [ -f flake.lock ]; then
    cp flake.lock flake.lock.bak
    # Discard any local modifications to flake.lock so git pull doesn't fail/conflict on it
    git checkout -- flake.lock
    has_bak=true
  fi

  local err=0
  git pull --rebase || err=$?

  if [ "$has_bak" = true ]; then
    if [ -f flake.lock.bak ]; then
      mv flake.lock.bak flake.lock
    fi
  fi

  if [ $err -ne 0 ]; then
    echo "git pull failed with exit code $err" >&2
    return $err
  fi
}

case "$cmd" in
  rebuild)
    rebuild
    ;;
  update)
    if [ "$no_flake" = true ]; then
      echo "Error: Cannot update flake inputs when --no-flake (-n) is set." >&2
      exit 1
    fi
    echo "Updating flake inputs..."
    sudo nix flake update
    ;;
  sync)
    echo "Pulling latest dotfiles from GitHub..."
    pull_repo
    echo "Dotfiles synced!"
    ;;
  sur)
    echo "=== Syncing repository ==="
    pull_repo
    if [ "$no_flake" = false ]; then
      echo "=== Updating flake inputs ==="
      sudo nix flake update
    fi
    echo "=== Rebuilding system ==="
    rebuild
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
  init)
    echo "Bootstrapping binary caches..."
    "$DOTFILES_DIR/scripts/add-caches.sh"
    ;;
  build-docs)
    nix-shell -p python3 --run "python3 docs/build.py"
    ;;
esac
