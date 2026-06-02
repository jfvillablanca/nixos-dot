# Centralized flake inputs declared via vic/flake-file.
#
# `flake-file.flakeModules.dendritic` enables the in-flake `.#write-flake` app
# (re-emits `flake.nix` from these declarations) and pre-wires both
# `flake-parts.flakeModules.modules` + `flake-file.flakeModules.import-tree`,
# matching our existing dendritic shape.
#
# Workflow when adding/removing/updating an input:
#   1. Edit `flake-file.inputs.<name>` (here, or in any per-feature module
#      that wants to colocate its own input — see plugins/oil/ for that
#      pattern).
#   2. `nix run .#write-flake` to regenerate `flake.nix`.
#   3. `nix flake lock` (or `nix flake update <name>`) to update the lock.
#   4. Commit `flake.nix` + `flake.lock` together.
#
# `nix flake check` fails when `flake.nix` is stale w.r.t. these declarations.
{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.flake-file.flakeModules.dendritic
    # Registers `flake.darwinConfigurations` as a top-level flake output;
    # flake-parts handles `flake.nixosConfigurations` natively but darwin
    # needs its own wiring.
    inputs.nix-darwin.flakeModules.default
  ];

  systems = ["x86_64-linux" "aarch64-darwin"];

  flake-file.inputs = {
    flake-file.url = lib.mkDefault "github:vic/flake-file";

    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable-24-05.url = "github:nixos/nixpkgs/nixos-24.05";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-colors.url = "github:misterio77/nix-colors";
    stylix.url = "github:danth/stylix";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    # nix-darwin master tracks `nixpkgs-unstable`, not `nixos-unstable`
    # (the two channels diverge -- nixos-unstable lags for darwin
    # compatibility). Carry a separate input so the Linux hosts can keep
    # following nixos-unstable unchanged.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };
}
