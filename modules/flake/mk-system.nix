# Transitional mkSystem factory + per-host nixosConfigurations sites.
#
# Holds the `lib.nixosSystem` invocation that the original flake.nix used to
# build every host. Each host still lives at `modules/hosts/<name>/` with
# underscore-prefixed entry files (`_configuration.nix`, `_home.nix`) that
# import-tree skips. Once each host is converted to a proper flake-parts
# module declaring its own `flake.nixosConfigurations.<name>`, the entry here
# can be deleted; when all four are gone, this whole file goes away.
{
  inputs,
  self,
  config,
  pkgs,
  pkgs-master,
  pkgs-stable-24-05,
  pkgs-stable-25-05,
  system,
  ...
}: let
  inherit (inputs.nixpkgs) lib;

  mkSystem = {
    user,
    hostName,
    base16Scheme,
    hostDir ? self + /modules/hosts/${hostName},
    configFile ? "_configuration.nix",
    homeFile ? "_home.nix",
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

        (hostDir + ("/" + configFile))

        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            extraSpecialArgs = {
              inherit inputs pkgs pkgs-master pkgs-stable-24-05 pkgs-stable-25-05 user system base16Scheme;
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
              (hostDir + ("/" + homeFile))
            ];
          };
        }
      ];
    };
in {
  flake.nixosConfigurations = {
    virt = mkSystem {
      user = "jmfv";
      hostName = "virt";
      base16Scheme = "gruvbox-material-dark-medium";
    };

    sartre = mkSystem {
      user = "jmfv";
      hostName = "sartre";
      base16Scheme = "rose-pine-moon";
    };
  };
}
