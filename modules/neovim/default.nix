{ config, pkgs, ... }:
let
    luaConfig = [
        ./lua/impatient.lua
        ./lua/options.lua
        ./lua/keymaps.lua
        ./lua/autocommands.lua
        ./lua/cmp.lua
        ./lua/lsp.lua
        # ./lua/typescript-nvim.lua -- need to package 
        # ./lua/markdownpreview.lua -- need to package 
        # ./lua/zk-nvim.lua -- need to package 
    ];
in
{
    home.packages = with pkgs; [
        # Treesitter complains for a C compiler on the PATH acc to checkhealth
        gcc

        # Formatters (can be exposed via flake.nix)
        nodePackages_latest.prettier                                        # webdev
        stylua                                                              # lua
        shfmt                                                               # sh
        nixpkgs-fmt                                                         # nix
        rustfmt                                                             # rust
        # python310Packages.black                                           # python

        # Linters (can be exposed via flake.nix)
        statix                                                              # nix
        shellcheck                                                          # sh
        # python310Packages.flake8                                          # python

        # Language Servers (can be exposed via flake.nix)
        nodePackages_latest.bash-language-server                            # sh
        nodePackages_latest."@tailwindcss/language-server"                  # tailwind
        nil                                                                 # nix
        gopls                                                               # go
        sumneko-lua-language-server                                         # lua
        rust-analyzer                                                       # rust
        haskellPackages.haskell-language-server                             # haskell
        # python311Packages.python-lsp-server                               # python

        nodePackages_latest.typescript-language-server                      # js-related grammars
        nodePackages_latest.vscode-langservers-extracted                    # html, css, json, eslint
        # nodePackages_latest.emmet-ls
    ];

    xdg.configFile."nvim/servers" = {
        source = ./lua/servers;
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
            plenary-nvim
            impatient-nvim
            nvim-web-devicons
            
            # nvim-tree
            {
                plugin = nvim-tree-lua;
                type = "lua";
                config = builtins.readFile ./lua/nvim-tree.lua;
            }
            # lualine
            {
                plugin = lualine-nvim;
                type = "lua";
                config = builtins.readFile ./lua/lualine.lua;
            }
            # toggleterm
            {
                plugin = toggleterm-nvim;
                type = "lua";
                config = builtins.readFile ./lua/toggleterm.lua;
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
            # autosession
            {
                plugin = auto-session;
                type = "lua";
                config = builtins.readFile ./lua/autosession.lua;
            }
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

            # LSP
            # nvim-lspconfig
            {
                plugin = nvim-lspconfig;
                type = "lua";
                config = ''
                require('lspconfig').nil_ls.setup({
                    cmd = { "${pkgs.nil}/bin/nil" }
                })
                require('lspconfig').lua_ls.setup({
                    cmd = { "${pkgs.lua-language-server}/bin/lua-language-server" }
                })
                '';
                # require('lspconfig').rust_analyzer.setup({})
                # require('lspconfig').gopls.setup({
                #     cmd = { "${pkgs.gopls}/bin/gopls" }
                # })
                # require('lspconfig').hls.setup({
                #     cmd = { "${pkgs.haskell-language-server}/bin/haskell-language-server" }
                # })
            }
            # null-ls
            {
                plugin = null-ls-nvim;
                type = "lua";
                config = builtins.readFile ./lua/null-ls.lua;
            }
            # refactoring
            {
                plugin = refactoring-nvim;
                type = "lua";
                config = builtins.readFile ./lua/refactoring.lua;
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
            telescope-manix

            # gitsigns
            {
                plugin = gitsigns-nvim;
                type = "lua";
                config = builtins.readFile ./lua/gitsigns.lua;
            }
            # comment-nvim
            {
                plugin = comment-nvim;
                type = "lua";
                config = builtins.readFile ./lua/comment.lua;
            }
                # Need to package
            # {
            #     plugin = nvim-ts-context-commentstring;
            #     type = "lua";
            # }
            # trouble-nvim
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
            {
                plugin = leap-nvim;
                type = "lua";
                config = builtins.readFile ./lua/leap.lua;
            }
            # wilder
            {
                plugin = wilder-nvim;
                type = "lua";
                config = builtins.readFile ./lua/wilder.lua;
            }
                # Test how zk would work in Nix
            # {
            #     plugin = zk-nvim;
            #     type = "lua";
            #     config = builtins.readFile ./lua/zk-nvim.lua;
            # }
            # {
            #     plugin = markdown-preview-nvim;
            #     type = "lua";
            #     config = builtins.readFile ./lua/markdownpreview.lua;
            # }
            # zen mode
            {
                plugin = zen-mode-nvim;
                type = "lua";
                config = builtins.readFile ./lua/zen-mode.lua;
            }
            # twilight-nvim
            {
                plugin = twilight-nvim;
                type = "lua";
                config = builtins.readFile ./lua/twilight.lua;
            }
            # nvim-highlight-colors
            {
                plugin = nvim-highlight-colors;
                type = "lua";
                config = builtins.readFile ./lua/nvim-highlight-colors.lua;
            }
            # nvim-lastplace
            {
                plugin = nvim-lastplace;
                type = "lua";
                config = builtins.readFile ./lua/nvim-lastplace.lua;
            }
            # kmonad (syntax highlighting)
            # {
            #     plugin = kmonad-vim;
            #     type = "lua";
            # }
            
            # Colorschemes
            {
                plugin = kanagawa-nvim;
                # plugin = tokyonight-nvim;
                # plugin = rose-pine;
                type = "lua";
                config = builtins.readFile ./lua/colorschemes/kanagawa.lua + ''
                local status_ok, _ = pcall(vim.cmd, "colorscheme " .. "kanagawa")
                if not status_ok then
                    return
                end
                '' + builtins.readFile ./lua/colorschemes/setbgtotransparent.lua;
            }
        ];
    };
}
