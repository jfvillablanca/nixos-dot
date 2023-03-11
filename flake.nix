{
  description = "jmfv's NixOs config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # outputs = { self, nixpkgs, ... }: 
  outputs = inputs@{ nixpkgs, home-manager, ... }: 
    {
      nixosConfigurations = {
        jmfv = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
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
