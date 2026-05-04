# Env-var finalize: runs after per-plugin configs and other spines (the spine
# name `zzz_env_finalize` sorts last alphabetically, so its `pcall(require, ...)`
# is the last spine to fire). Applies foreign-host portability overrides:
#
# - NVIM_TRUECOLOR=0 — clear termguicolors for capability-poor terminals.
# - NVIM_LOCAL_INIT (default ~/.config/nvim-local/init.lua) — source per-machine
#   tweaks without rebuilding.
#
# NVIM_COLORSCHEME is handled inline by the wrapper's customRC since the
# colorscheme command lives there alongside the build-time default.
_: {
  flake.modules.nvim.lib-env-finalize = {
    nvim.spineLua.zzz_env_finalize = ''
      -- _spine_zzz_env_finalize.lua: synthesized.
      -- See modules/programs/neovim-experimental/lib/env-finalize/default.nix.

      -- NVIM_TRUECOLOR=0 forces termguicolors off for terminals that don't
      -- support 24-bit color. Runs after core options sets termguicolors=true.
      if vim.env.NVIM_TRUECOLOR == "0" then
        vim.opt.termguicolors = false
      end

      -- NVIM_LOCAL_INIT: source per-machine init.lua last, if present.
      -- Defaults to $HOME/.config/nvim-local/init.lua. Pcall'd so a
      -- syntax error doesn't break startup.
      do
        local local_init = vim.env.NVIM_LOCAL_INIT
        if not local_init or local_init == "" then
          local_init = (vim.env.HOME or "") .. "/.config/nvim-local/init.lua"
        end
        if vim.fn.filereadable(local_init) == 1 then
          local ok, err = pcall(dofile, local_init)
          if not ok then
            vim.notify("nvim-local: " .. tostring(err), vim.log.levels.WARN)
          end
        end
      end
    '';
  };
}
