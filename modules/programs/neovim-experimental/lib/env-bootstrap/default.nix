# Env-var bootstrap: populate `_G.NVIM_DISABLED` and `_G.nvim_disabled(name)`
# from the NVIM_DISABLE env var BEFORE per-plugin configs run. Plugins that
# need network/auth/host-specific tooling can opt into the gate by checking
# `_G.nvim_disabled("<short-name>")` and returning early.
#
# Priority: lib.mkOrder 100 — lower than mkBefore=500, so this lua chunk
# precedes core options/keymaps/autocommands (mkBefore) in extraLuaConfig.
{lib, ...}: {
  flake.modules.nvim.lib-env-bootstrap = {
    config.nvim.extraLuaConfig = lib.mkOrder 100 ''
      -- Env-var bootstrap. Runs before core options + per-plugin configs.
      -- See modules/programs/neovim-experimental/lib/env-bootstrap/default.nix.

      ---@type table<string, boolean>
      _G.NVIM_DISABLED = {}
      for s in (vim.env.NVIM_DISABLE or ""):gmatch("[^,]+") do
        local trimmed = s:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
          _G.NVIM_DISABLED[trimmed] = true
        end
      end

      ---@param name string
      ---@return boolean
      function _G.nvim_disabled(name)
        return _G.NVIM_DISABLED[name] == true
      end
    '';
  };
}
