{
  description = "jmfv's NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };

    # walker.url = "github:abenz1267/walker";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-colors.url = "github:misterio77/nix-colors";

    stylix.url = "github:danth/stylix";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    # Hyprland
    hyprland = {
      # NOTE: Tracking issue: https://github.com/hyprwm/Hyprland/issues/5891
      # XWayland clipboard issue: https://github.com/hyprwm/Hyprland/issues/6132#issuecomment-2127283895
      type = "git";
      url = "https://github.com/hyprwm/Hyprland";
      submodules = true;
      rev = "4cdddcfe466cb21db81af0ac39e51cc15f574da9";
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
        neovim-nightly-overlay.overlays.default
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
      base16Scheme,
    }:
      lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs pkgs-stable user system base16Scheme;
        };
        modules = [
          inputs.disko.nixosModules.default
          inputs.impermanence.nixosModules.impermanence
          inputs.stylix.nixosModules.stylix
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
              extraSpecialArgs = {
                inherit inputs pkgs pkgs-stable user system base16Scheme;
              };
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
        base16Scheme = "gruvbox-material-dark-medium";
      };

      t14g1 = mkSystem {
        inherit pkgs pkgs-stable system;
        user = "jmfv";
        hostName = "t14g1";
        base16Scheme = "gruvbox-dark-hard";
      };

      cimmerian = mkSystem {
        inherit pkgs pkgs-stable system;
        user = "jmfv";
        hostName = "cimmerian";
        base16Scheme = "rose-pine-moon";
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
