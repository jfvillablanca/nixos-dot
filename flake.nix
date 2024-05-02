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
    nix-colors.url = "github:misterio77/nix-colors";

    # Hyprland
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = {
    nixpkgs,
    home-manager,
    neovim-nightly-overlay,
    nixos-hardware,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        neovim-nightly-overlay.overlay
      ];
    };

    inherit (nixpkgs) lib;

    mkSystem = {
      pkgs,
      system,
      user,
      hostName,
      systemModules,
    }:
      lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs user;};
        modules =
          [
            {
              networking.hostName = hostName;
              users.users.${user} = {
                isNormalUser = true;
                description = user;
                extraGroups = [
                  "networkmanager"
                  "wheel"
                  "uinput"
                  "input"
                  "sound"
                  "audio"
                  "video"
                  "docker"
                ];
              };
            }

            ./nixosModules
            ./hosts/${hostName}/configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                extraSpecialArgs = {inherit inputs pkgs user;};
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${user}.imports = [
                  ./homeModules
                  ./hosts/${hostName}/home.nix
                ];
              };
            }
          ]
          ++ systemModules;
      };
  in {
    nixosConfigurations = {
      virt = mkSystem {
        inherit pkgs system;
        user = "jmfv";
        hostName = "virt";
        systemModules = [];
      };

      t14g1 = mkSystem {
        inherit pkgs system;
        user = "jmfv";
        systemModules = [
          nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen1
        ];
      };

      cimmerian = mkSystem {
        inherit pkgs system;
        user = "jmfv";
        hostName = "cimmerian";
        systemModules = [];
      };
    };
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        stylua
        selene
        sumneko-lua-language-server

        alejandra
        statix
        deadnix
        nil
      ];
      formatter = pkgs.alejandra;
    };
  };
}
