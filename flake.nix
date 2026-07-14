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

    nixarr = {
      url = "github:nix-media-server/nixarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, chaotic, home-manager, home-manager-unstable, nixos-hardware, ... }@inputs:
    let
      sharedArgsFor = system:
        let
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
            config.permittedInsecurePackages = [
              "pnpm-9.15.9"
              "pnpm-10.29.2"
            ];
          };
        in {
          customPackages = {
            better-control = if inputs.custom-packages.packages ? ${system} && inputs.custom-packages.packages.${system} ? better-control
                             then inputs.custom-packages.packages.${system}.better-control
                             else pkgs-unstable.writeShellScriptBin "better-control" "echo 'better-control is not supported on ${system}'";
            brave-origin = if inputs.custom-packages.packages ? ${system} && inputs.custom-packages.packages.${system} ? brave-origin
                           then inputs.custom-packages.packages.${system}.brave-origin
                           else pkgs-unstable.writeShellScriptBin "brave-origin" "echo 'brave-origin is not supported on ${system}'";
          };
          inherit inputs pkgs-unstable;
        };

      sharedKernelAndCache = { pkgs, ... }: {
        imports = [
          inputs.chaotic.nixosModules.default
        ];

        nixpkgs.overlays = [
          inputs.nix-cachyos-kernel.overlays.default
        ];

        #boot.kernelPackages = pkgs.linuxPackages_cachyos;
        boot.kernelPackages = pkgs.linuxPackages_latest;

        # Binary cache
        nix.settings.substituters = [
          "https://attic.xuyh0120.win/lantian"
          "https://cache.xinux.uz"
        ];
        nix.settings.trusted-public-keys = [
          "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
          "cache.xinux.uz:BXCrtqejFjWzWEB9YuGB7X2MV4ttBur1N8BkwQRdH+0="
        ];
        nix.settings.extra-substituters = [
          "https://jovian.cachix.org"
          "https://nyx-cache.chaotic.cx"
        ];
        nix.settings.extra-trusted-public-keys = [
          "jovian.cachix.org-1:8Vq4Txku6VZIRhYrHYki3Ab9XHJRoWmdYqMqj4rB/Uc="
          "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
        ];
      };
    in
    {
      nixosConfigurations = {

        # --- PotatoMonster — MangoWM Desktop ---
        PotatoMonster = nixpkgs.lib.nixosSystem {
          specialArgs = sharedArgsFor "x86_64-linux";
          system = "x86_64-linux";
          modules = [
            sharedKernelAndCache
            inputs.mangowm.nixosModules.mango
            ./hosts/potatomonster

            # Home-Manager as NixOS module
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-bak";
              home-manager.users.niwatorichan = import ./home/potatomonster.nix;
            }
          ];
        };

        # --- PwPoulet — KDE Plasma 6 Desktop ---
        PwPoulet = nixpkgs.lib.nixosSystem {
          specialArgs = sharedArgsFor "x86_64-linux";
          system = "x86_64-linux";
          modules = [
            sharedKernelAndCache
            inputs.jovian.nixosModules.default
            ./hosts/pwpoulet

            # Home-Manager as NixOS module
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-bak";

              home-manager.users.niwatorichan = import ./home/pwpoulet.nix;
            }
          ];
        };

        # --- Jeff — Headless ---
        Jeff = nixpkgs.lib.nixosSystem {
          specialArgs = sharedArgsFor "x86_64-linux";
          system = "x86_64-linux";
          modules = [
            sharedKernelAndCache
            ./hosts/jeff

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-bak";
              home-manager.users.niwatorichan = import ./home/jeff.nix;
            }
          ];
        };

        # --- PetitePatate — Pinebook Pro ARM64 ---
        PetitePatate = nixpkgs.lib.nixosSystem {
          specialArgs = sharedArgsFor "aarch64-linux";
          system = "aarch64-linux";
          modules = [
            inputs.nixos-hardware.nixosModules.pine64-pinebook-pro
            ./hosts/petitepatate

            # Home-Manager as NixOS module
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-bak";
              home-manager.users.niwatorichan = import ./home/petitepatate.nix;
            }
          ];
        };

        # --- Savage — Steam Deck LCD ---
        Savage = nixpkgs-unstable.lib.nixosSystem {
          specialArgs = sharedArgsFor "x86_64-linux";
          system = "x86_64-linux";
          modules = [
            sharedKernelAndCache
            inputs.jovian.nixosModules.default
            ./hosts/savage

            # Home-Manager as NixOS module
            home-manager-unstable.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-bak";
              home-manager.users.niwatorichan = import ./home/savage.nix;
            }
          ];
        };

      };
    };
}
