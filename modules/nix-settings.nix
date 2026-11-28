# Nix daemon settings shared by all hosts: binary caches, garbage collection, store optimisation.
{ lib, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheel" ];

    # Download & substitution throughput
    download-buffer-size = 268435456; # 256 MiB (default 1 MiB throttles large NARs)
    http-connections = 50;
    max-substitution-jobs = 32;
    connect-timeout = 5;
    fallback = true;
    builders-use-substitutes = true;
    auto-optimise-store = true;

    # Use extra-* so the default cache.nixos.org entry is always queried first.
    # Module-specific caches (noctalia, jovian) are declared in their own modules.
    extra-substituters = [
      "https://cache.lantian.pub/lantian"
    ];
    extra-trusted-public-keys = [
      "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="
    ];
  };

  # Hosts may override these (e.g. jovian-deck.nix sets a shorter retention).
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 14d";
  };
  nix.optimise.automatic = lib.mkDefault true;
}
