{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Not pinned to our nixpkgs on purpose: both ship their own kernel/package
    # sets built against a specific nixpkgs so their binary caches keep hitting.
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };

    mangowm = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    custom-packages = {
      url = "github:Rishabh5321/custom-packages-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Savage (the only Jovian host) runs on nixpkgs-unstable.
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, home-manager-unstable, nixos-hardware, ... }@inputs:
    let
      insecurePackages = import ./lib/insecure-packages.nix;

      sharedArgsFor = system:
        let
          mkPkgs = src: import src {
            inherit system;
            config.allowUnfree = true;
            config.permittedInsecurePackages = insecurePackages;
          };
          pkgs-unstable = mkPkgs nixpkgs-unstable;
          pkgs-stable = mkPkgs nixpkgs;
        in {
          customPackages = {
            brave-origin = if inputs.custom-packages.packages ? ${system} && inputs.custom-packages.packages.${system} ? brave-origin
                           then inputs.custom-packages.packages.${system}.brave-origin
                           else pkgs-unstable.writeShellScriptBin "brave-origin" "echo 'brave-origin is not supported on ${system}'";
          };
          inherit inputs pkgs-unstable pkgs-stable;
        };

      sharedKernelAndCache = { config, pkgs, lib, ... }: {
        imports = [
          inputs.chaotic.nixosModules.default
        ];

        nixpkgs.overlays = [
          inputs.nix-cachyos-kernel.overlays.pinned
        ];

        #boot.kernelPackages = pkgs.linuxPackages_cachyos;
        boot.kernelPackages = lib.mkIf (config.networking.hostName != "Savage") pkgs.linuxPackages_latest;
      };

      # Build a NixOS host with Home-Manager wired in.
      #   name         – host name (informational; the key in nixosConfigurations is what counts)
      #   system       – target platform
      #   nixpkgs'/hm  – channel and Home-Manager flavour (stable by default)
      #   hostDir      – ./hosts/<dir>
      #   homeFile     – ./home/<file>.nix
      #   extraModules – modules inserted before the host directory
      mkHost =
        { name
        , system ? "x86_64-linux"
        , nixpkgs' ? nixpkgs
        , hm ? home-manager
        , hostDir
        , homeFile
        , extraModules ? [ ]
        }:
        let
          sharedArgs = sharedArgsFor system;
        in
        nixpkgs'.lib.nixosSystem {
          inherit system;
          specialArgs = sharedArgs;
          modules = extraModules ++ [
            hostDir

            # Home-Manager as NixOS module
            hm.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-bak";
              home-manager.extraSpecialArgs = sharedArgs;
              home-manager.users.niwatorichan = import homeFile;
            }
          ];
        };

      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      nixosConfigurations = {
        # --- PotatoMonster — MangoWM Desktop ---
        PotatoMonster = mkHost {
          name = "PotatoMonster";
          hostDir = ./hosts/potatomonster;
          homeFile = ./home/potatomonster.nix;
          extraModules = [ sharedKernelAndCache inputs.mangowm.nixosModules.mango ];
        };

        # --- PetitOeuf — Laptop Configuration ---
        PetitOeuf = mkHost {
          name = "PetitOeuf";
          hostDir = ./hosts/petitoeuf;
          homeFile = ./home/petitoeuf.nix;
          extraModules = [ sharedKernelAndCache inputs.mangowm.nixosModules.mango ];
        };

        # --- PwPoulet — KDE Plasma 6 Desktop ---
        PwPoulet = mkHost {
          name = "PwPoulet";
          hostDir = ./hosts/pwpoulet;
          homeFile = ./home/pwpoulet.nix;
          extraModules = [ sharedKernelAndCache ];
        };

        # --- Jeff — Headless ---
        Jeff = mkHost {
          name = "Jeff";
          hostDir = ./hosts/jeff;
          homeFile = ./home/jeff.nix;
          extraModules = [ sharedKernelAndCache ];
        };

        # --- PetitePatate — Pinebook Pro ARM64 ---
        PetitePatate = mkHost {
          name = "PetitePatate";
          system = "aarch64-linux";
          hostDir = ./hosts/petitepatate;
          homeFile = ./home/petitepatate.nix;
          extraModules = [ inputs.nixos-hardware.nixosModules.pine64-pinebook-pro ];
        };

        # --- Savage — Steam Deck LCD ---
        Savage = mkHost {
          name = "Savage";
          nixpkgs' = nixpkgs-unstable;
          hm = home-manager-unstable;
          hostDir = ./hosts/savage;
          homeFile = ./home/savage.nix;
          extraModules = [ sharedKernelAndCache inputs.jovian.nixosModules.default ];
        };
      };

      formatter = forAllSystems (pkgs: pkgs.nixfmt);

      # `nix flake check` builds every host of the current platform.
      # Use `nix flake check --no-build` for a fast evaluation-only pass.
      checks = forAllSystems (pkgs:
        nixpkgs.lib.mapAttrs' (n: c: nixpkgs.lib.nameValuePair "host-${n}" c.config.system.build.toplevel)
          (nixpkgs.lib.filterAttrs (_: c: c.pkgs.stdenv.hostPlatform.system == pkgs.stdenv.hostPlatform.system) self.nixosConfigurations));

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.nixfmt
            pkgs.statix
            pkgs.deadnix
            pkgs.nixd
            inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];
        };
      });
    };
}
