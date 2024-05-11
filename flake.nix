{
  description = "jmfv's NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
    walker.url = "github:abenz1267/walker";
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
    nixpkgs-stable,
    home-manager,
    neovim-nightly-overlay,
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
    pkgs-stable = import nixpkgs-stable {inherit system;};

    inherit (nixpkgs) lib;

    mkSystem = {
      pkgs,
      pkgs-stable,
      system,
      user,
      hostName,
    }:
      lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs pkgs-stable user system;};
        modules = [
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

            # Don't touch me :)
            system.stateVersion = "22.11";
          }

          ./nixosModules
          ./hosts/${hostName}/configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              extraSpecialArgs = {inherit inputs pkgs pkgs-stable user;};
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${user}.imports = [
                {
                  home = {
                    username = "${user}";
                    homeDirectory = "/home/${user}";
                    # Don't touch me :)
                    stateVersion = "22.11";
                  };
                }
                ./homeModules
                ./hosts/${hostName}/home.nix
              ];
            };
          }
        ];
      };
  in {
    nixosConfigurations = {
      virt = mkSystem {
        inherit pkgs pkgs-stable system;
        user = "jmfv";
        hostName = "virt";
      };

      t14g1 = mkSystem {
        inherit pkgs pkgs-stable system;
        user = "jmfv";
        hostName = "t14g1";
      };

      cimmerian = mkSystem {
        inherit pkgs pkgs-stable system;
        user = "jmfv";
        hostName = "cimmerian";
      };
    };
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        stylua
        selene
        lua-language-server

        alejandra
        statix
        deadnix
        nil
        # nixd
      ];
      formatter = pkgs.alejandra;
    };
  };
}
