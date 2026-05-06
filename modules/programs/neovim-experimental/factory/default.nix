# `flake.factory.nvim` — Factory Aspect that produces a wrapped nvim
# derivation parameterized by host preferences (colorscheme, debug/markdown
# tools, extra LSP servers via extraModules). Mirrors the
# `flake.factory.user` pattern used in modules/factory/user/.
#
# The aggregator (../default.nix) calls this with no overrides for the base
# `.#nvim-experimental` package; per-host packages in modules/flake/packages.nix
# call it with their stylix slug + tool gates.
{
  inputs,
  self,
  lib,
  ...
}: let
  # Module-system option introspection for nixd autocomplete. Same module
  # set the factory uses (skeleton + `flake.modules.nvim.default` aggregator)
  # but evaluated once at flake-eval time with default args, so nixd can
  # complete `nvim.lsp.servers.<tab>` / `nvim.plugins.<tab>` etc. from any
  # buffer. Exposed at `flake.nvimOptions` (top-level — flake-parts
  # doesn't recursively merge `flake.lib` across modules) and consumed at
  # host nixd call sites + the stable nvim's nixd.lua.
  nvimOptionEval = lib.evalModules {
    specialArgs = {
      inherit inputs lib;
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    };
    modules = [
      ../_skeleton-options.nix
      self.modules.nvim.default
    ];
  };
in {
  # Independently-advanceable nightly-overlay used only by
  # `flake.packages.x86_64-linux.nvim-experimental`. Bumping this never
  # moves cimmerian's daily-driver `.#nvim`, and vice versa. Advance via
  # `nix flake update neovim-nightly-overlay-experimental`.
  flake-file.inputs.neovim-nightly-overlay-experimental = {
    url = "github:nix-community/neovim-nightly-overlay";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.nvimOptions = nvimOptionEval.options;

  flake.factory.nvim = {
    system,
    colorscheme ? null,
    base16 ? false,
    debugEnable ? false,
    markdownPreviewEnable ? false,
    extraOverlays ? [],
    extraModules ? [],
  }: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays =
        [
          inputs.neovim-nightly-overlay-experimental.overlays.default
          # Skip flaky upstream tests. neotest's treesitter parsing test is
          # broken in nixpkgs's pinned grammars; rustaceanvim depends on it
          # transitively. Override the lua-package layer.
          (_: prev: {
            luajit = prev.luajit.override {
              packageOverrides = _: luaprev: {
                neotest = luaprev.neotest.overrideAttrs (_: {doCheck = false;});
              };
            };
          })
        ]
        ++ extraOverlays;
    };

    eval = lib.evalModules {
      specialArgs = {inherit inputs lib pkgs;};
      modules =
        [
          ../_skeleton-options.nix
          self.modules.nvim.default
          {
            nvim.colorscheme = lib.mkDefault colorscheme;
            nvim.base16-nvim.enable = lib.mkDefault base16;
            nvim.tools.debug.enable = lib.mkDefault debugEnable;
            nvim.tools.markdown-preview.enable = lib.mkDefault markdownPreviewEnable;
          }
        ]
        ++ extraModules;
    };

    cfg = eval.config.nvim;
  in
    pkgs.callPackage ../_wrapper.nix {
      plugins = cfg.plugins.list;
      inherit (cfg) extraPackages extraLuaConfig colorscheme spineLua withNodeJs withPython3 withRuby;
    };
}
