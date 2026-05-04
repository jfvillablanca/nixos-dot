# Top-level options for the experimental nvim package. Fed to `lib.evalModules`
# in `./default.nix` together with the collected `flake.modules.nvim.*`
# contributions. Spine modules under ./lib/<name>/ declare their own
# additional options on top of these.
{lib, ...}: {
  options.nvim = {
    plugins.list = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          plugin = lib.mkOption {
            type = lib.types.package;
            description = "The plugin derivation. Override at the per-plugin module's `package` option to swap revs.";
          };
          type = lib.mkOption {
            type = lib.types.enum ["lua" "viml"];
            default = "lua";
          };
          config = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Per-plugin setup snippet (lua or vimL, per `type`).";
          };
          optional = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "If true, plugin lands in pack/*/opt/ instead of pack/*/start/. Phase 2 lazy runner uses this.";
          };
          # Lazy-loading triggers. Data-only in Phase 1; consumed by the
          # Phase 2 lazy runner when `optional = true`.
          lazy.event = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
          lazy.cmd = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
          lazy.ft = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
          lazy.keys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
        };
      });
      default = [];
      description = "Aggregate plugin spec list. Each plugin module appends its own entry.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Runtime tools added to the wrapped nvim's PATH (LSP servers, formatters, linters, etc).";
    };

    extraLuaConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Top-level lua sourced before per-plugin configs. Core options/keymaps/autocommands land here.";
    };

    colorscheme = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Colorscheme name passed to `vim.cmd.colorscheme(...)` at the end of the
        bootstrap. If null, neovim falls back to its bundled default. Hosts
        consuming this package via the factory pass their stylix/nix-colors slug.
      '';
    };

    spineLua = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = {};
      description = ''
        Synthesized lua emitted by spines under ./lib/<name>/. Each entry becomes
        a `lua/_spine_<name>.lua` file in the wrapped nvim's runtimepath, then
        `pcall(require, "_spine_<name>")`-loaded by the bootstrap. Editable in-nvim
        for debugging via `:edit $VIMRUNTIME/lua/_spine_<name>.lua`.
      '';
    };

    tools = {
      debug.enable = lib.mkEnableOption "debug adapter protocol support (nvim-dap + adapters)";
      markdown-preview.enable = lib.mkEnableOption "markdown-preview.nvim (requires withNodeJs)";
    };

    withNodeJs = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Wrap nvim with a node provider. Auto-enabled when copilot or markdown-preview are on.";
    };
    withPython3 = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    withRuby = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };
}
