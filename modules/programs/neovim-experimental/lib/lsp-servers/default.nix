# Cross-cutting LSP-servers spine. Per-server modules under
# ../../lsp/servers/<name>/ contribute to `nvim.lsp.servers.<name>` (package +
# filetypes + cmd + settings); this module emits the synthesized `_spine_lsp.lua`
# that calls `vim.lsp.config` + `vim.lsp.enable` per enabled server, and adds
# server packages to `nvim.extraPackages` so they're on the wrapped nvim's PATH.
#
# Replaces nvim-lspconfig with native API stable since neovim 0.11.
{lib, ...}: {
  flake.modules.nvim.lib-lsp-servers = {config, ...}: {
    options.nvim.lsp.servers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          enable = lib.mkEnableOption "LSP server ${name}";
          package = lib.mkOption {
            type = lib.types.package;
            description = "Server derivation. Override per-server module's `package` to swap revs.";
          };
          cmd = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Command + args invoking the server. Per-server module sets a default via `lib.getExe`.";
          };
          filetypes = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Filetypes the server attaches to.";
          };
          root_markers = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [".git"];
            description = "Files/dirs whose presence anchors the workspace root.";
          };
          settings = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = {};
            description = "Server settings, roundtripped through vim.json to the LSP `settings` block.";
          };
          init_options = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = {};
            description = "Server init_options, roundtripped through vim.json.";
          };
        };
      }));
      default = {};
      description = "Cross-cutting LSP server registry. Per-server modules under ../../lsp/servers/ contribute.";
    };

    config = let
      enabled = lib.filterAttrs (_: srv: srv.enable) config.nvim.lsp.servers;

      # Each server's lua-side config record. Settings/init_options are
      # JSON-encoded; vim.json.decode produces the right Lua tables.
      lspJson = builtins.toJSON (lib.mapAttrs (_: srv: {
          inherit (srv) cmd filetypes root_markers settings init_options;
        })
        enabled);
    in {
      nvim.extraPackages = lib.mapAttrsToList (_: srv: srv.package) enabled;

      nvim.spineLua.lsp = ''
        -- _spine_lsp.lua: synthesized from `nvim.lsp.servers.*.{cmd,filetypes,...}`.
        -- See modules/programs/neovim-experimental/lib/lsp-servers/default.nix.
        -- Uses native vim.lsp.config + vim.lsp.enable (neovim 0.11+).

        ---@class NvimSpineLspServer
        ---@field cmd string[]
        ---@field filetypes string[]
        ---@field root_markers string[]
        ---@field settings table
        ---@field init_options table

        ---@type table<string, NvimSpineLspServer>
        local servers = vim.json.decode([==[${lspJson}]==])

        for name, cfg in pairs(servers) do
          vim.lsp.config(name, cfg)
          vim.lsp.enable(name)
        end
      '';
    };
  };
}
