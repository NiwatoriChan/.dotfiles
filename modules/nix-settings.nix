# Nix daemon settings shared by all hosts: binary caches, garbage collection, store optimisation.
{ lib, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

    # Use extra-* so the default cache.nixos.org entry is never replaced.
    extra-substituters = [
      "https://attic.xuyh0120.win/lantian"
      "https://cache.xinux.uz"
      "https://jovian.cachix.org"
      "https://nyx-cache.chaotic.cx"
    ];
    extra-trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "cache.xinux.uz:BXCrtqejFjWzWEB9YuGB7X2MV4ttBur1N8BkwQRdH+0="
      "jovian.cachix.org-1:8Vq4Txku6VZIRhYrHYki3Ab9XHJRoWmdYqMqj4rB/Uc="
      "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
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
