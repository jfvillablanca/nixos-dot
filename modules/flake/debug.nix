# Expose flake-parts' option tree at `outputs.debug.options` so nixd can
# autocomplete `perSystem.<tab>` and `flake.modules.<class>.<name>` while
# editing dendritic modules.
#
# Per flake-parts/modules/debug.nix: setting `debug = true` adds three
# outputs — `debug`, `allSystems`, `currentSystem` — each carrying the
# resolved `config` plus `options`, `extendModules`, `_module`. nixd
# consumes `outputs.debug.options` via:
#
#   settings.nixd.options.flake_parts.expr =
#     ''(builtins.getFlake "/path").debug.options'';
#
# wired at host-specific call sites (modules/flake/packages.nix for the
# experimental factory; modules/programs/neovim/lua/lsp/servers/nixd.lua
# for the stable nvim).
{
  debug = true;
}
