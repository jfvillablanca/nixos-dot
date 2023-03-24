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
        nodePackages_latest.prettier
        stylua
        shfmt
        nixpkgs-fmt

        nodePackages_latest.bash-language-server
        nodePackages_latest.typescript-language-server
        nodePackages_latest.tailwindcss

        nil
        gopls
        sumneko-lua-language-server
        rust-analyzer
        haskellPackages.haskell-language-server
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
                # require('lspconfig').tsserver.setup({})
                # require('lspconfig').tailwindcss.setup({})
                # require('lspconfig').bashls.setup({})
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

            # Telescope
            {
                plugin = telescope-nvim;
                type = "lua";
                config = builtins.readFile ./lua/telescope.lua;
            }
            # telescope-fzf-native-nvim
            
            # Treesitter
            {
                plugin = nvim-treesitter.withAllGrammars;
                type = "lua";
                config = builtins.readFile ./lua/treesitter.lua;
            }

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
