# `inputs.self.lib.mkNixos "cimmerian"` constructs a NixOS configuration
# that pulls the host feature `flake.modules.nixos.<hostName>` plus the
# framework-level modules (disko, stylix, nixos-wsl, home-manager).
# Impermanence (or any other persistence backend) is imported by the
# `persistence` Aspect at `modules/system/persistence/default.nix`, not
# here, so swapping backends stays a one-file change.
#
# `mkDarwin` is the macOS counterpart. Pulls
# `flake.modules.darwin.<hostName>` plus home-manager and nix-homebrew.
# disko, impermanence, and nixos-wsl have no Darwin analogue.
{
  inputs,
  self,
  pkgs-master,
  pkgs-stable-24-05,
  pkgs-stable-25-05,
  ...
}: {
  flake.lib.mkNixos = hostName:
    inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs pkgs-master pkgs-stable-24-05 pkgs-stable-25-05;
      };
      modules = [
        inputs.disko.nixosModules.default
        inputs.stylix.nixosModules.stylix
        inputs.nixos-wsl.nixosModules.default
        inputs.home-manager.nixosModules.home-manager

        # Apply the same overlays modules/flake/pkgs.nix uses so the
        # nixosSystem-internal pkgs has neovim-nightly, the spotify-player
        # auth fix, and our local `vf` package available.
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = [
            inputs.neovim-nightly-overlay.overlays.default
            (import (self + /modules/programs/spotify-player/_overlay.nix))
            (final: _prev: {
              vf = final.callPackage (self + /packages/by-name/v/vf) {};
              vfx = final.callPackage (self + /packages/by-name/v/vfx) {};
            })
          ];
        }

        self.modules.nixos.${hostName}
      ];
    };

  flake.lib.mkDarwin = hostName:
    inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = {
        inherit inputs;
      };
      modules = [
        inputs.home-manager.darwinModules.home-manager
        inputs.nix-homebrew.darwinModules.nix-homebrew

        {
          nixpkgs.hostPlatform = "aarch64-darwin";
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = [
            inputs.neovim-nightly-overlay.overlays.default
          ];
        }

        self.modules.darwin.${hostName}
      ];
    };
}
