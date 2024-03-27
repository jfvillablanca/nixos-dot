{
  config,
  pkgs,
  ...
}: let
  luaConfig = [
    ./lua/options.lua
    ./lua/keymaps.lua
    ./lua/autocommands.lua
    ./lua/cmp.lua # requires luasnip
    ./lua/lsp/main.lua
  ];
in {
  xdg.configFile."nvim/lua/lsp" = {
    source = ./lua/lsp;
    recursive = true;
  };

  programs.neovim = {
    enable = true;
    package = pkgs.neovim-nightly;
    defaultEditor = true;
    vimAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;

    extraLuaConfig =
      builtins.concatStringsSep "\n"
      (map builtins.readFile luaConfig);

    plugins = with pkgs.vimPlugins; [
      # nvim-tree
      {
        plugin = nvim-tree-lua;
        type = "lua";
        config = ''
          require("nvim-tree").setup()
        '';
        # config = builtins.readFile ./lua/nvim-tree.lua;
      }

      # lualine
      {
        plugin = lualine-nvim;
        type = "lua";
        config = builtins.readFile ./lua/lualine.lua;
      }

      # indent-blankline
      {
        plugin = indent-blankline-nvim;
        type = "lua";
        config = builtins.readFile ./lua/indentline.lua;
      }

      # autopairs
      {
        plugin = nvim-autopairs;
        type = "lua";
        config = builtins.readFile ./lua/autopairs.lua;
      }

      # nvim-surround
      {
        plugin = nvim-surround;
        type = "lua";
        config = builtins.readFile ./lua/nvim-surround.lua;
      }

      # treesj
      {
        plugin = treesj;
        type = "lua";
        config = builtins.readFile ./lua/treesj.lua;
      }

      # # autosession
      # # {
      # #     plugin = auto-session;
      # #     type = "lua";
      # #     config = builtins.readFile ./lua/autosession.lua;
      # # }

      # # persistence-nvim
      # {
      #   plugin = persistence-nvim;
      #   type = "lua";
      #   config = ''
      #     require("persistence").setup()
      #   '';
      # }

      # which-key
      {
        plugin = which-key-nvim;
        type = "lua";
        config = builtins.readFile ./lua/whichkey.lua;
      }

      # Cmp
      nvim-cmp
      cmp-buffer
      cmp-path
      cmp_luasnip
      cmp-nvim-lsp
      cmp-nvim-lua

      # Snippets
      luasnip
      friendly-snippets

      # neogen
      {
        plugin = neogen;
        type = "lua";
        config = ''
          require("neogen").setup({ snippet_engine = "luasnip" })
        '';
      }

      # LSP
      nvim-lspconfig

      # Typescript
      {
        plugin = typescript-tools-nvim;
        type = "lua";
        config = builtins.readFile ./lua/typescript-tools-nvim.lua;
      }

      # Haskell
      haskell-tools-nvim

      # Rust
      # # crates.nvim
      # {
      #   plugin = crates-nvim;
      #   type = "lua";
      #   config = builtins.readFile ./lua/crates.nvim.lua;
      # }

      # rust-tools-nvim
      {
        plugin = rust-tools-nvim;
        type = "lua";
        config = builtins.readFile ./lua/rust-tools-nvim.lua;
      }

      # # refactoring
      # {
      #   plugin = refactoring-nvim;
      #   type = "lua";
      #   config = builtins.readFile ./lua/refactoring.lua;
      # }

      # null-ls
      {
        plugin = none-ls-nvim;
        type = "lua";
        config = builtins.readFile ./lua/null-ls.lua;
      }

      # Telescope
      {
        plugin = telescope-nvim;
        type = "lua";
        config = builtins.readFile ./lua/telescope.lua;
      }

      # Treesitter
      {
        plugin = nvim-treesitter.withAllGrammars;
        type = "lua";
        config = builtins.readFile ./lua/treesitter.lua;
      }
      nvim-treesitter-textobjects
      nvim-treesitter-context

      # gitsigns
      {
        plugin = gitsigns-nvim;
        type = "lua";
        config = builtins.readFile ./lua/gitsigns.lua;
      }
      vim-fugitive

      # octo-nvim
      {
        plugin = octo-nvim;
        type = "lua";
        config = builtins.readFile ./lua/octo-nvim.lua;
      }

      # comment-nvim
      {
        plugin = comment-nvim;
        type = "lua";
        config = builtins.readFile ./lua/comment.lua;
      }

      # nvim-ts-context-commentstring
      #   config is integrated with comment-nvim
      nvim-ts-context-commentstring

      # nvim-ts-autotag
      {
        plugin = nvim-ts-autotag;
        type = "lua";
        config = builtins.readFile ./lua/nvim-ts-autotag.lua;
      }

      # trouble-nvim
      nvim-web-devicons # optional requirement for trouble-nvim
      {
        plugin = trouble-nvim;
        type = "lua";
        config = builtins.readFile ./lua/trouble.lua;
      }
      # todo-comments
      {
        plugin = todo-comments-nvim;
        type = "lua";
        config = builtins.readFile ./lua/todo-comments.lua;
      }

      # leap
      # {
      #   plugin = leap-nvim;
      #   type = "lua";
      #   config = builtins.readFile ./lua/leap.lua;
      # }

      # flash.nvim
      {
        plugin = flash-nvim;
        type = "lua";
        config = builtins.readFile ./lua/flash-nvim.lua;
      }

      # noice.nvim
      {
        plugin = noice-nvim;
        type = "lua";
        config = builtins.readFile ./lua/noice.lua;
      }

      # # wilder
      # {
      #   plugin = wilder-nvim;
      #   type = "lua";
      #   config = builtins.readFile ./lua/wilder.lua;
      # }

      # # Test how zk would work in Nix
      # # {
      # #     plugin = zk-nvim;
      # #     type = "lua";
      # #     config = builtins.readFile ./lua/zk-nvim.lua;
      # # }

      {
        plugin = markdown-preview-nvim;
        type = "lua";
        config = builtins.readFile ./lua/markdownpreview.lua;
      }

      # # zen mode
      # {
      #   plugin = zen-mode-nvim;
      #   type = "lua";
      #   config = builtins.readFile ./lua/zen-mode.lua;
      # }

      # # twilight-nvim
      # {
      #   plugin = twilight-nvim;
      #   type = "lua";
      #   config = builtins.readFile ./lua/twilight.lua;
      # }

      # nvim-highlight-colors
      {
        plugin = nvim-highlight-colors;
        type = "lua";
        config = builtins.readFile ./lua/nvim-highlight-colors.lua;
      }

      # # nvim-lastplace                                            # deprecated
      # {
      #   plugin = nvim-lastplace;
      #   type = "lua";
      #   config = builtins.readFile ./lua/nvim-lastplace.lua;
      # }

      # # kmonad-vim (kbd syntax highlighting)
      # kmonad-vim

      # -- null-ls is back, no longer need conform.nvim and nvim-lint
      # # conform-nvim
      # {
      #     plugin = conform-nvim;
      #     type = "lua";
      #     config = builtins.readFile ./lua/conform-nvim.lua;
      # }

      # # nvim-lint
      # {
      #     plugin = nvim-lint;
      #     type = "lua";
      #     config = builtins.readFile ./lua/nvim-lint.lua;
      # }

      # vimtex
      {
        plugin = vimtex;
        type = "viml";
        config = ''
          " This is necessary for VimTeX to load properly. The "indent" is optional.
          " Note that most plugin managers will do this automatically.
          filetype plugin indent on

          " This enables Vim's and neovim's syntax-related features. Without this, some
          " VimTeX features will not work (see ":help vimtex-requirements" for more
          " info).
          syntax enable

          " Viewer options: One may configure the viewer either by specifying a built-in
          " viewer method:
          let g:vimtex_view_method = 'zathura'

          " Or with a generic interface:
          let g:vimtex_view_general_viewer = 'okular'
          let g:vimtex_view_general_options = '--unique file:@pdf\#src:@line@tex'

          " VimTeX uses latexmk as the default compiler backend. If you use it, which is
          " strongly recommended, you probably don't need to configure anything. If you
          " want another compiler backend, you can change it as follows. The list of
          " supported backends and further explanation is provided in the documentation,
          " see ":help vimtex-compiler".
          let g:vimtex_compiler_method = 'latexmk'

          " Most VimTeX mappings rely on localleader and this can be changed with the
          " following line. The default is usually fine and is the symbol "\".
          let maplocalleader = "\\"
        '';
      }

      # Colorschemes
      gruvbox
      tokyonight-nvim
      rose-pine
      catppuccin-nvim
      {
        plugin = kanagawa-nvim;
        type = "lua";
        config =
          builtins.readFile ./lua/colorschemes/rosepine.lua
          + ''
            local status_ok, _ = pcall(vim.cmd, "colorscheme " .. "rose-pine")
            if not status_ok then
                return
            end
          ''
          + builtins.readFile ./lua/colorschemes/setsemantichighlight.lua;
        #  + builtins.readFile ./lua/colorschemes/setbgtotransparent.lua;
      }
    ];

    extraPackages = with pkgs; [
      # Treesitter complains for a C compiler on the PATH acc to checkhealth
      gcc

      # Formatters
      # rustfmt                                                                   # rust
      codespell # general (fix common misspellings)
      # nodePackages_latest.prettier                                              # webdev
      # stylelint                                                                 # css
      # rustywind                                                                 # tailwind
      shfmt # sh
      # python311Packages.black                                                   # python

      # Linters
      shellcheck # sh
      # python311Packages.flake8                                                  # python
      write-good # english prose

      # Language Servers
      nodePackages_latest.bash-language-server # sh
      # gopls                                                                     # go
      # rust-analyzer                                                             # rust
      # haskellPackages.haskell-language-server                                   # haskell
      # python311Packages.python-lsp-server                                       # python

      nodePackages_latest."@tailwindcss/language-server" # tailwind
      nodePackages_latest."@prisma/language-server" # prisma
      nodePackages_latest.typescript-language-server # js-related grammars
      nodePackages_latest.vscode-langservers-extracted # html, css, json, eslint
      nodePackages_latest.volar # vue
      emmet-ls # html snippets

      texlab # LaTeX
    ];
  };
}
