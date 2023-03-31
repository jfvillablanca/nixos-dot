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
  };

  outputs = { nixpkgs, home-manager, neovim-nightly-overlay, ... }:
    let
      user = "jmfv";
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
        ${user} = lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, ... }: import ./systems/virt/configuration.nix {
              inherit config pkgs isWayland user;
            })
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.jmfv.imports = [
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
