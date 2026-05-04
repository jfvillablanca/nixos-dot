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
          preConfigLua = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = ''
              Lua snippet inserted into the spine's per-server setup block,
              before `vim.lsp.config(name, cfg)`. Has access to `cfg` (the
              decoded config table). Use to populate runtime-only fields like
              `cfg.settings.Lua.workspace.library = vim.api.nvim_get_runtime_file("", true)`
              that can't roundtrip through JSON.
            '';
          };
        };
      }));
      default = {};
      description = "Cross-cutting LSP server registry. Per-server modules under ../../lsp/servers/ contribute.";
    };

    config = let
      enabled = lib.filterAttrs (_: srv: srv.enable) config.nvim.lsp.servers;

      # JSON-encoded static config per server. Per-server `preConfigLua` runs
      # before `vim.lsp.config` so it can mutate `cfg` to add runtime fields.
      serverBlock = name: srv: let
        staticJson = builtins.toJSON {
          inherit (srv) cmd filetypes root_markers settings init_options;
        };
      in ''
        do
          local cfg = vim.json.decode([==[${staticJson}]==])
          ${srv.preConfigLua}
          vim.lsp.config(${builtins.toJSON name}, cfg)
          vim.lsp.enable(${builtins.toJSON name})
        end
      '';
    in {
      nvim.extraPackages = lib.mapAttrsToList (_: srv: srv.package) enabled;

      nvim.spineLua.lsp = ''
        -- _spine_lsp.lua: synthesized from `nvim.lsp.servers.*`.
        -- See modules/programs/neovim-experimental/lib/lsp-servers/default.nix.
        -- Uses native vim.lsp.config + vim.lsp.enable (neovim 0.11+).

        ${lib.concatStringsSep "\n" (lib.mapAttrsToList serverBlock enabled)}
      '';
    };
  };
}
