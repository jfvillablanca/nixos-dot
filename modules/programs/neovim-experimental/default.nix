# Aggregator for the experimental nvim package.
#
# Two responsibilities:
#
# 1. Collector: every nvim-class module declared elsewhere
#    (`flake.modules.nvim.<name>`) is gathered into
#    `flake.modules.nvim.default` via module-system imports, so a single
#    entry point composes the full config.
#
# 2. Build: `flake.packages.x86_64-linux.nvim-experimental` evaluates the
#    collected module set with `lib.evalModules` against the option types
#    in `./_skeleton-options.nix`, then feeds the result to
#    `./_wrapper.nix` (a callPackage helper that wraps nvim-unwrapped).
#
# The build path goes through neither nixosConfigurations nor home-manager.
# `pkgs` here is built from `inputs.neovim-nightly-overlay-experimental` so
# bumping that input never touches cimmerian's `.#nvim`.
{
  inputs,
  lib,
  self,
  ...
}: {
  flake.modules.nvim.default.imports =
    lib.attrValues
    (lib.filterAttrs (n: _: n != "default") (self.modules.nvim or {}));

  perSystem = {system, ...}: {
    packages.nvim-experimental = let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          inputs.neovim-nightly-overlay-experimental.overlays.default
        ];
      };

      eval = lib.evalModules {
        specialArgs = {inherit inputs lib pkgs;};
        modules = [
          ./_skeleton-options.nix
          self.modules.nvim.default
        ];
      };

      cfg = eval.config.nvim;
    in
      pkgs.callPackage ./_wrapper.nix {
        plugins = cfg.plugins.list;
        inherit (cfg) extraPackages extraLuaConfig colorscheme spineLua withNodeJs withPython3 withRuby;
      };
  };
}
