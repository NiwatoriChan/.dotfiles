# Single source of truth for permitted insecure packages.
# Used by flake.nix (pkgs-stable / pkgs-unstable) and hosts/common/base.nix.
# Prune entries as soon as the package that needs them is updated.
[
  "pnpm-9.15.9"
  "pnpm-10.29.2"
  "electron-41.9.1"
  "electron-41.10.7"
]
