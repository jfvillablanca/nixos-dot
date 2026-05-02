# `inputs.self.lib.mkNixos "cimmerian"` constructs a NixOS configuration
# that pulls the host feature `flake.modules.nixos.<hostName>` plus the
# framework-level modules (disko, impermanence, stylix, nixos-wsl,
# home-manager). Each host's `modules/hosts/<name>/default.nix` calls
# `mkNixos` directly to set its own `flake.nixosConfigurations.<name>`.
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
        # Cross-cutting constant (single user across hosts). Migrated to
        # the Constants Aspect in B8.
        user = "jmfv";
      };
      modules = [
        inputs.disko.nixosModules.default
        inputs.impermanence.nixosModules.impermanence
        inputs.stylix.nixosModules.stylix
        inputs.nixos-wsl.nixosModules.default
        inputs.home-manager.nixosModules.home-manager

        # Apply the same overlays modules/flake/pkgs.nix uses so the
        # nixosSystem-internal pkgs has neovim-nightly etc available.
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = [
            inputs.neovim-nightly-overlay.overlays.default
            (import (self + /modules/programs/spotify-player/_overlay.nix))
          ];
        }

        self.modules.nixos.${hostName}
      ];
    };
}
