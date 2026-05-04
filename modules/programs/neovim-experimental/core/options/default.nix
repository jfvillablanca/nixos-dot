# Core options. Sourced before plugin contributions via `lib.mkBefore` so
# settings like `tabstop` and `ignorecase` are in place when plugins load.
# Treesitter foldexpr/foldmethod are NOT set here — they're applied per-buffer
# by the treesitter spine when a parser is available.
{lib, ...}: {
  flake.modules.nvim.core-options = {
    config.nvim.extraLuaConfig = lib.mkBefore (builtins.readFile ./_options.lua);
  };
}
