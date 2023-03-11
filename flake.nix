{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # home-manager = {
    #   url = github:nix-community/home-manager;
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  # outputs = { self, nixpkgs, home-manager, ... }: 
  outputs = { self, nixpkgs, ... }: 
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
	config.allowUnfree = true;
      };
      lib = nixpkgs.lib;
    in {
      nixosConfigurations = {
        jmfv = lib.nixosSystem {
	  inherit system;
	  modules = [
	  ./configuration.nix
	  # home-manager.nixosModules.home-manager 
	  # {
	  #   home-manager.useGlobalPkgs = true;
	  #   home-manager.useUserPackages = true;
	  #   home-manager.users.jmfv = {
	  #     imports = [ ./home.nix ];
	  #   };
	  # } 
	  ];
	};
      };
    };
}
