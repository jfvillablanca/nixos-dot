# Core keymaps + leader. Sourced before plugin contributions so `<leader>`
# resolves to the configured key when plugin keymaps are registered.
{lib, ...}: {
  flake.modules.nvim.core-keymaps = {
    config.nvim.extraLuaConfig = lib.mkBefore (builtins.readFile ./_keymaps.lua);
  };
}
