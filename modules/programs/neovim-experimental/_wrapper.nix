# callPackage helper: takes the evaluated `nvim.*` config from the aggregator
# and produces a wrapped nvim derivation. No home-manager, no NixOS — just
# `wrapNeovimUnstable` over the bare binary plus a synthesized bootstrap.
#
# The neovim wrapper concatenates each plugin's `config` into a single init.vim
# (vimL). Lua-typed plugin configs need explicit `lua << EOF ... EOF` wrapping
# at the per-plugin level so they're sourced as lua, not vimL.
{
  lib,
  neovim-unwrapped,
  wrapNeovimUnstable,
  neovimUtils,
  vimUtils,
  symlinkJoin,
  writeTextFile,
  plugins,
  extraPackages,
  extraLuaConfig,
  colorscheme,
  spineLua,
  withNodeJs,
  withPython3,
  withRuby,
}: let
  spineFiles = lib.mapAttrsToList (name: content:
    writeTextFile {
      name = "nvim-spine-${name}";
      text = content;
      destination = "/lua/_spine_${name}.lua";
    })
  spineLua;

  spinePlugin = vimUtils.buildVimPlugin {
    pname = "nvim-experimental-spines";
    version = "0";
    src = symlinkJoin {
      name = "nvim-experimental-spines-src";
      paths = spineFiles;
    };
  };

  # Wrap each lua-typed per-plugin config in a `lua << EOF ... EOF` block so
  # neovim's wrapper (which concatenates configs into a single vimL init.vim)
  # sources them as lua. vimL configs pass through untouched.
  wrapPlugin = p: let
    ty = p.type or "lua";
    cfg = p.config or "";
    wrapped =
      if cfg == ""
      then ""
      else if ty == "lua"
      then "lua << EOF\n${cfg}\nEOF"
      else cfg;
  in {
    inherit (p) plugin;
    config = wrapped;
    optional = p.optional or false;
  };

  allPlugins =
    map wrapPlugin plugins
    ++ lib.optional (spineLua != {}) {plugin = spinePlugin;};

  spineRequires =
    lib.concatMapStringsSep "\n"
    (name: ''pcall(require, "_spine_${name}")'')
    (lib.attrNames spineLua);

  # Bootstrap is sourced as lua via customLuaRC. Order:
  # - extraLuaConfig (core options/keymaps/autocommands; mkBefore-priority).
  # - per-plugin configs run between (via init.vim), since this lua block
  #   precedes `vim.cmd.source "init.vim"` in the wrapped rcContent.
  # - spine require()s (after plugins set themselves up).
  # - colorscheme, last.
  #
  # Spines are appended via customRC (sourced as lua via the trailing
  # `vim.cmd("lua << EOF ... EOF")` so they run after per-plugin configs.
  customLuaRC = extraLuaConfig;

  customRC = ''
    lua << EOF
    -- Spines (synthesized; see modules/programs/neovim-experimental/lib/<name>/).
    ${spineRequires}

    -- Colorscheme: NVIM_COLORSCHEME env var wins over the build-time default.
    -- See lib/env-bootstrap/ + lib/env-finalize/ for the other env hooks.
    do
      local cs = vim.env.NVIM_COLORSCHEME
      ${lib.optionalString (colorscheme != null) ''
      if not cs or cs == "" then cs = "${colorscheme}" end
    ''}
      if cs and cs ~= "" then
        pcall(vim.cmd.colorscheme, cs)
      end
    end
    EOF
  '';

  nvimConfig = neovimUtils.makeNeovimConfig {
    inherit withNodeJs withPython3 withRuby customLuaRC;
    plugins = allPlugins;
    inherit customRC;
  };
in
  wrapNeovimUnstable neovim-unwrapped (nvimConfig
    // {
      wrapperArgs =
        nvimConfig.wrapperArgs
        ++ lib.optionals (extraPackages != []) [
          "--prefix"
          "PATH"
          ":"
          "${lib.makeBinPath extraPackages}"
        ];
    })
