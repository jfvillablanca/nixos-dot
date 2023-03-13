{
  description = "jmfv's NixOs config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  # outputs = inputs@{ nixpkgs, home-manager, neovim-nightly-overlay, ... }: 
  outputs = inputs@{ nixpkgs, home-manager, ... }: 
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
    };
    lib = nixpkgs.lib;
    # overlays = [
    #     neovim-nightly-overlay.overlay
    # ];
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
