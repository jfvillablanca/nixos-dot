# Core autocommands. No mkBefore/mkAfter needed — autocmds register lazily
# and don't fire until the trigger event.
_: {
  flake.modules.nvim.core-autocommands = {
    config.nvim.extraLuaConfig = builtins.readFile ./_autocommands.lua;
  };
}
