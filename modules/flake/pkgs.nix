# Build the pkgs / pkgs-master / pkgs-stable-* variants used across the flake
# and expose them via _module.args so any other flake-parts module can pull
# them in via `{ pkgs, pkgs-master, ... }` arguments.
{
  inputs,
  self,
  ...
}: let
  system = "x86_64-linux";

  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      inputs.neovim-nightly-overlay.overlays.default

      # NOTE: Authentication Issue
      # https://github.com/aome510/spotify-player/issues/802#issuecomment-3191659178
      (import (self + /modules/programs/spotify-player/_overlay.nix))
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
in {
  _module.args = {
    inherit system pkgs pkgs-master pkgs-stable-24-05 pkgs-stable-25-05;
  };
}
