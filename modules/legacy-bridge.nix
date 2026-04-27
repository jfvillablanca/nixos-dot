# Phase-1 dendritic bridge.
#
# Re-implements the original `mkSystem` factory inside a flake-parts module so
# the existing `./nixosModules`, `./homeModules`, and `./hosts/<name>` layout
# keeps producing identical store paths. Modules are ported into the dendritic
# tree one at a time; this bridge shrinks as that happens and is deleted in
# the final cleanup phase.
{
  inputs,
  self,
  lib,
  config,
  ...
}: let
  # Home-manager modules that have been ported into the dendritic tree.
  # Each entry comes from a `modules/home/*.nix` file that sets
  # `flake.homeModules.<name>`. They are appended to every home-manager
  # imports list below so the legacy `./homeModules/default.nix`
  # aggregator can be shrunk one entry at a time.
  ported-home-modules = builtins.attrValues config.flake.homeModules;

  system = "x86_64-linux";

  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      inputs.neovim-nightly-overlay.overlays.default

      # NOTE: Authentication Issue
      # https://github.com/aome510/spotify-player/issues/802#issuecomment-3191659178
      (import (self + /modules/home/spotify-player/_overlay.nix))
    ];
  };
  pkgs-master = import inputs.nixpkgs-master {
    inherit system;
    config.allowUnfree = true;
  };
  pkgs-stable-24-05 = import inputs.nixpkgs-stable-24-05 {inherit system;};
  pkgs-stable-25-05 = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      inputs.neovim-nightly-overlay.overlays.default
    ];
  };

  inherit (inputs.nixpkgs) lib;

  mkSystem = {
    user,
    hostName,
    base16Scheme,
  }:
    lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs pkgs-master pkgs-stable-24-05 pkgs-stable-25-05 user system base16Scheme;
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

        (self + /nixosModules)
        (self + /hosts/${hostName}/configuration.nix)

        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            extraSpecialArgs = {
              inherit inputs pkgs pkgs-master pkgs-stable-24-05 pkgs-stable-25-05 user system base16Scheme;
            };
            useGlobalPkgs = false;
            useUserPackages = true;
            users.${user}.imports =
              [
                {
                  home = {
                    username = "${user}";
                    homeDirectory = "/home/${user}";
                    # Don't touch me :)
                    stateVersion = "22.11";
                  };
                }
                (self + /homeModules)
                (self + /hosts/${hostName}/home.nix)
              ]
              ++ ported-home-modules;
          };
        }
      ];
    };
in {
  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = {};
    description = "Home-manager modules ported into the dendritic tree.";
  };

  config.flake.nixosConfigurations = {
    virt = mkSystem {
      user = "jmfv";
      hostName = "virt";
      base16Scheme = "gruvbox-material-dark-medium";
    };

    t14g1 = mkSystem {
      user = "jmfv";
      hostName = "t14g1";
      base16Scheme = "gruvbox-dark-hard";
    };

    cimmerian = mkSystem {
      user = "jmfv";
      hostName = "cimmerian";
      base16Scheme = "spaceduck";
    };

    sartre = mkSystem {
      user = "jmfv";
      hostName = "sartre";
      base16Scheme = "rose-pine-moon";
    };
  };

  config.flake.homeConfigurations = {
    "jmfv" = inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      extraSpecialArgs = rec {
        inherit inputs pkgs pkgs-stable-24-05 system;
        user = "jmfv";
        base16Scheme = "rose-pine-moon";
      };
      modules =
        [
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
          (self + /homeModules)
          (self + /hosts/sartre/home.nix)
        ]
        ++ ported-home-modules;

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

  config.flake.devShells.${system}.default = pkgs.mkShell {
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

  config.flake.templates = let
    basic = {
      path = self + /templates/basic;
      description = "A basic flake with devenv.";
    };
  in {
    inherit basic;
    default = basic;
  };
}
