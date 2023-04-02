{
  description = "jmfv's NixOs config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
  };

  outputs = { nixpkgs, home-manager, neovim-nightly-overlay, nixos-hardware, ... }:
    let
      user = "jmfv";
      hosts = {
        virt = "virt";
        t14g1 = "t14g1";
      };
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          neovim-nightly-overlay.overlay
        ];
      };
      inherit (nixpkgs) lib;
      isWayland = false;
    in
    {
      nixosConfigurations = {
        ${hosts.virt} = lib.nixosSystem {
          # NOTE: Will probably be broken once I start messing 
          # with global system settings for laptop 
          inherit system;
          modules = [
            ({ config, ... }: import ./systems/virt/configuration.nix {
              inherit config pkgs isWayland user;
              hostName = hosts.virt;
            })
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${user}.imports = [
                ({ config, ... }: import ./home.nix {
                  inherit config pkgs lib isWayland user;
                })
              ];
            }
          ];
        };

        ${hosts.t14g1} = lib.nixosSystem {
          inherit system;
          modules = [
            nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen1
            ({ config, ... }: import ./systems/t14g1/configuration.nix {
              inherit config pkgs isWayland user;
              hostName = hosts.t14g1;
            })
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${user}.imports = [
                ({ config, ... }: import ./home.nix {
                  inherit config pkgs lib isWayland user;
                })
              ];
            }
          ];
        };
      };
    };
}
