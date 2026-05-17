# `inputs.self.lib.mkNixos "cimmerian"` constructs a NixOS configuration
# that pulls the host feature `flake.modules.nixos.<hostName>` plus the
# framework-level modules (disko, stylix, nixos-wsl, home-manager).
# Impermanence (or any other persistence backend) is imported by the
# `persistence` Aspect at `modules/system/persistence/default.nix`, not
# here, so swapping backends stays a one-file change.
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
}
