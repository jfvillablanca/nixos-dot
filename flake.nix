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

  outputs = { nixpkgs, home-manager, neovim-nightly-overlay, ... }@inputs: 
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
            neovim-nightly-overlay.overlay
        ];
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
                home-manager.users.jmfv = import ./home.nix {inherit pkgs;};
              } 
          ];
        };
      };
    };
}
