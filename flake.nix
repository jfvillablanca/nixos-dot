{
  description = "jmfv's NixOs config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # neovim.url = "github:neovim/neovim";
    # neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = { nixpkgs, home-manager, ... }@inputs: 
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        # overlays = [
        #     (import (
        #         builtins.fetchTarball {
        #             url = builtins.getAttr "url" (inputs.neovim-nightly-overlay.overlay);
        #         }
        #     ))
        # ];
    };
    lib = nixpkgs.lib;
  in
    {
      nixosConfigurations = {
        jmfv = lib.nixosSystem {
            inherit system;
          modules = [
              ./configuration.nix
              home-manager.nixosModules.home-manager 
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.jmfv = import ./home.nix;
              } 
          ];
        };
      };
    };
}
