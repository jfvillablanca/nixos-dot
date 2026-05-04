# Cross-cutting keymap spine. Plugins contribute keymaps to `nvim.keymaps`;
# this module emits the synthesized `_spine_keymaps.lua` that calls
# `vim.keymap.set` per entry. Phase 2 swaps the consumer for which-key (which
# reads the same option) so plugins never reach into which-key directly.
{lib, ...}: {
  flake.modules.nvim.lib-keymaps = {config, ...}: {
    options.nvim.keymaps = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          mode = lib.mkOption {
            type = with lib.types; either str (listOf str);
            default = "n";
            description = "Mode (or list of modes) the mapping applies to.";
          };
          lhs = lib.mkOption {
            type = lib.types.str;
            description = "Trigger key sequence.";
          };
          rhs = lib.mkOption {
            type = lib.types.str;
            description = ''
              Right-hand side as a string. For lua function callbacks, set the
              keymap inside the plugin's `_config.lua` directly — function
              values can't roundtrip through the spine's JSON encoding.
            '';
          };
          desc = lib.mkOption {
            type = lib.types.str;
            description = "Human-readable description (consumed by which-key in Phase 2).";
          };
          group = lib.mkOption {
            type = with lib.types; nullOr str;
            default = null;
            description = "Optional which-key group name (e.g. \"git\", \"lsp\").";
          };
          buffer = lib.mkOption {
            type = with lib.types; nullOr (either bool int);
            default = null;
          };
          silent = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          noremap = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          expr = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
        };
      });
      default = [];
      description = "Cross-cutting keymap registry; emitted as `_spine_keymaps.lua`.";
    };

    config.nvim.spineLua.keymaps = let
      keymapsJson =
        builtins.toJSON
        (map (km: lib.filterAttrs (_: v: v != null) km) config.nvim.keymaps);
    in ''
      -- _spine_keymaps.lua: synthesized from `nvim.keymaps` option.
      -- See modules/programs/neovim-experimental/lib/keymaps/default.nix.
      -- Phase 1 consumer: vim.keymap.set. Phase 2 consumer: which-key.

      ---@class NvimSpineKeymap
      ---@field mode string|string[]
      ---@field lhs string
      ---@field rhs string
      ---@field desc string
      ---@field group? string
      ---@field buffer? integer|boolean
      ---@field silent? boolean
      ---@field noremap? boolean
      ---@field expr? boolean

      ---@type NvimSpineKeymap[]
      local keymaps = vim.json.decode([==[${keymapsJson}]==])

      for _, km in ipairs(keymaps) do
        vim.keymap.set(km.mode, km.lhs, km.rhs, {
          desc = km.desc,
          silent = km.silent,
          noremap = km.noremap,
          expr = km.expr,
          buffer = km.buffer,
        })
      end
    '';
  };
}
