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
  imports = [inputs.flake-file.flakeModules.dendritic];

  # Match the previous explicit `systems = ["x86_64-linux"]` in flake.nix.
  # `flakeModules.dendritic` would otherwise enable all systems and `nix flake
  # show` / CI would try to evaluate aarch64-darwin etc.
  systems = ["x86_64-linux"];

  flake-file.inputs = {
    flake-file.url = lib.mkDefault "github:vic/flake-file";

    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable-24-05.url = "github:nixos/nixpkgs/nixos-24.05";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Independently-advanceable nightly-overlay used only by
    # `flake.packages.x86_64-linux.nvim-experimental`. Bumping this never
    # moves cimmerian's daily-driver `.#nvim`, and vice versa. Advance via
    # `nix flake update neovim-nightly-overlay-experimental`.
    neovim-nightly-overlay-experimental = {
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

    impermanence.url = "github:nix-community/impermanence";

    hyprland = {
      type = "git";
      url = "https://github.com/hyprwm/Hyprland";
      submodules = true;
    };

    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
