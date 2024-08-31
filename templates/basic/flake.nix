{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devenv.url = "github:cachix/devenv";
  };

  outputs = {
    self,
    nixpkgs,
    devenv,
    flake-utils,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        ## unfree packages you want to enable
        # config.allowUnfreePredicate = pkg:
        #   builtins.elem (nixpkgs.lib.getName pkg) [ ];
      };
    in {
      devShells.default = devenv.lib.mkShell {
        inherit inputs pkgs;
        modules = [
          {
            ## Optional name for the shell
            # name = "My pearly shell";
            languages = {
              nix.enable = true;
              ## Add more languages depending on your project
            };
            ## Add more packages required in the shell
            # packages = with pkgs; [ ];
          }
        ];
      };
    });
}
