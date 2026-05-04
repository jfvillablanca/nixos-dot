# Treesitter spine — Path B "passive parser asset".
#
# nvim-treesitter (master, archived) sits in rtp as the source of parsers +
# queries; we do NOT call its `setup{ highlight = { enable = true } }`.
# Highlight is started natively per FileType via `vim.treesitter.start()`.
#
# textobjects + context (Phase 2) plug into nvim-treesitter.configs.setup{}
# for their respective subsystems and continue to work since the plugin is
# in the runtimepath.
_: {
  flake.modules.nvim.lib-treesitter = {
    config,
    pkgs,
    lib,
    ...
  }: {
    options.nvim.treesitter.package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
      description = ''
        Treesitter parser+query asset. Override to swap nixpkgs's pinned
        rev or to use a custom grammar bundle. Sits in rtp passively;
        highlight is `vim.treesitter.start()`, not `setup{}`.
      '';
    };

    config = {
      nvim.plugins.list = [
        {plugin = config.nvim.treesitter.package;}
      ];

      nvim.spineLua.treesitter = ''
        -- _spine_treesitter.lua: synthesized.
        -- See modules/programs/neovim-experimental/lib/treesitter/default.nix.
        -- Path B: nvim-treesitter is a passive parser+query asset; highlight
        -- starts natively per FileType.

        vim.api.nvim_create_autocmd("FileType", {
          group = vim.api.nvim_create_augroup("NvimSpineTreesitter", { clear = true }),
          ---@param args { buf: integer, match: string }
          callback = function(args)
            -- pcall: parsers may be absent for some filetypes (e.g. plain text).
            local ok = pcall(vim.treesitter.start, args.buf)
            if ok then
              vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
              vim.wo[0][0].foldmethod = "expr"
            end
          end,
        })
      '';
    };
  };
}
