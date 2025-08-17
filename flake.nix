{
  description = "jmfv's NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-stable-24-05.url = "github:nixos/nixpkgs/nixos-24.05";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

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
      type = "git";
      url = "https://github.com/hyprwm/Hyprland";
      submodules = true;
    };

    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:MarceColl/zen-browser-flake";
  };

  outputs = {
    nixpkgs,
    nixpkgs-stable-24-05,
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
        # inputs.copyparty.overlays.default

        # NOTE: Authentication Issue
        # https://github.com/aome510/spotify-player/issues/802#issuecomment-3191659178
        (import ./homeModules/spotify-player/overlay.nix)
      ];
    };
    pkgs-stable-24-05 = import nixpkgs-stable-24-05 {inherit system;};

    inherit (nixpkgs) lib;

    mkSystem = {
      pkgs,
      pkgs-stable-24-05,
      system,
      user,
      hostName,
      base16Scheme,
    }:
      lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs pkgs-stable-24-05 user system base16Scheme;
        };
        modules = [
          inputs.disko.nixosModules.default
          inputs.impermanence.nixosModules.impermanence
          inputs.stylix.nixosModules.stylix
          inputs.nixos-wsl.nixosModules.default
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
              extraSpecialArgs = {
                inherit inputs pkgs pkgs-stable-24-05 user system base16Scheme;
              };
              useGlobalPkgs = false;
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
        inherit pkgs pkgs-stable-24-05 system;
        user = "jmfv";
        hostName = "virt";
        base16Scheme = "gruvbox-material-dark-medium";
      };

      t14g1 = mkSystem {
        inherit pkgs pkgs-stable-24-05 system;
        user = "jmfv";
        hostName = "t14g1";
        base16Scheme = "gruvbox-dark-hard";
      };

      cimmerian = mkSystem {
        inherit pkgs pkgs-stable-24-05 system;
        user = "jmfv";
        hostName = "cimmerian";
        base16Scheme = "rose-pine-moon";
      };

      sartre = mkSystem {
        inherit pkgs pkgs-stable-24-05 system;
        user = "jmfv";
        hostName = "sartre";
        base16Scheme = "rose-pine-moon";
      };
    };
    homeConfigurations = {
      "jmfv" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = rec {
          inherit inputs pkgs pkgs-stable-24-05 system;
          user = "jmfv";
          base16Scheme = "rose-pine-moon";
        };
        modules = [
          {
            home = {
              # username = "${user}";
              # homeDirectory = "/home/${user}";
              username = "jmfv";
              homeDirectory = "/home/jmfv";
              # Don't touch me :)
              stateVersion = "22.11";
            };
            programs.home-manager.enable = true;
          }
          inputs.stylix.homeManagerModules.stylix

          # fonts
          {
            fonts.fontconfig.enable = true;
            home.packages = with pkgs; [
              source-code-pro
              font-awesome
              corefonts
              jetbrains-mono
              nerd-fonts.fira-code
              nerd-fonts.jetbrains-mono
            ];
          }
          ./homeModules
          ./hosts/sartre/home.nix
        ];

        # useGlobalPkgs = true;
        # useUserPackages = true;
        # users.${user}.imports = [
        #   {
        #     home = {
        #       username = "${user}";
        #       homeDirectory = "/home/${user}";
        #       # Don't touch me :)
        #       stateVersion = "22.11";
        #     };
        #   }
        #   ./homeModules
        #   ./hosts/${hostName}/home.nix
        # ];
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
        nixd
      ];
      formatter = pkgs.alejandra;
    };
    templates = let
      basic = {
        path = ./templates/basic;
        description = "A basic flake with devenv.";
      };
    in {
      inherit basic;
      default = basic;
    };
  };
}
