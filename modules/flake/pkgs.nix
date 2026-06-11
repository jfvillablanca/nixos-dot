# Build the pkgs / pkgs-master / pkgs-stable-* variants used across the flake
# and expose them via _module.args so any other flake-parts module can pull
# them in via `{ pkgs, pkgs-master, ... }` arguments.
{
  inputs,
  self,
  ...
}: let
  system = "x86_64-linux";

  packagesOverlay = final: _prev: {
    vf = final.callPackage (self + /packages/by-name/v/vf) {};
    vfx = final.callPackage (self + /packages/by-name/v/vfx) {};
  };

  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      inputs.neovim-nightly-overlay.overlays.default

      # NOTE: Authentication Issue
      # https://github.com/aome510/spotify-player/issues/802#issuecomment-3191659178
      (import (self + /modules/programs/spotify-player/_overlay.nix))

      packagesOverlay
    ];
  };

  pkgs-master = import inputs.nixpkgs-master {
    inherit system;
    config.allowUnfree = true;
  };

  # firefox-devedition is pinned to this 24.05 stable instance (see
  # modules/programs/firefox); its speech-dispatcher pulls ~645 MiB of
  # mbrola-voices. We do not use TTS, so strip mbrola here too.
  pkgs-stable-24-05 = import inputs.nixpkgs-stable-24-05 {
    inherit system;
    overlays = [
      # firefox-devedition is pinned to this 24.05 instance (see
      # modules/programs/firefox); its speech-dispatcher pulls ~645 MiB of
      # mbrola-voices. We do not use TTS, so build speechd with an mbrola-free
      # espeak (overriding espeak-ng alone does not reach speechd's `espeak`).
      (_: prev: let
        espeak' = prev.espeak-ng.override {mbrolaSupport = false;};
      in {
        espeak-ng = espeak';
        speechd = prev.speechd.override {espeak = espeak';};
      })
    ];
  };

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
