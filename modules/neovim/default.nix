{ config, pkgs, ... }:
let
    luaConfig = [
        ./lua/impatient.lua
        ./lua/options.lua
        ./lua/keymaps.lua
        ./lua/autocommands.lua

            ./lua/colorschemes/rosepine.lua
            ./lua/colorschemes/kanagawa.lua
        ./lua/colorscheme.lua
        
        ./lua/cmp.lua

        ./lua/lsp/lsp.lua
        ./lua/lsp/null-ls.lua
        # ./lua/typescript-nvim.lua -- need to package 
    ];
in
{
    home.packages = with pkgs; [
        nodePackages_latest.prettier
        stylua
        shfmt

        nodePackages_latest.bash-language-server
        nodePackages_latest.typescript-language-server
        nodePackages_latest.tailwindcss

        nil
        gopls
        sumneko-lua-language-server
        rust-analyzer
        haskellPackages.haskell-language-server
    ];

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
            
            {
                plugin = nvim-tree-lua;
                type = "lua";
                config = builtins.readFile ./lua/nvim-tree.lua;
            }
            {
                plugin = lualine-nvim;
                type = "lua";
                config = builtins.readFile ./lua/lualine.lua;
            }
            {
                plugin = toggleterm-nvim;
                type = "lua";
                config = builtins.readFile ./lua/toggleterm.lua;
            }
            {
                plugin = indent-blankline-nvim;
                type = "lua";
                config = builtins.readFile ./lua/indentline.lua;
            }
            {
                plugin = which-key-nvim;
                type = "lua";
                config = builtins.readFile ./lua/whichkey.lua;
            }

            # Colorschemes
            tokyonight-nvim
            rose-pine
            kanagawa-nvim

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
                require('lspconfig').tsserver.setup({})
                require('lspconfig').tailwindcss.setup({})
                require('lspconfig').bashls.setup({})
                '';
                # require('lspconfig').rust_analyzer.setup({})
                # require('lspconfig').gopls.setup({
                #     cmd = { "${pkgs.gopls}/bin/gopls" }
                # })
                # require('lspconfig').hls.setup({
                #     cmd = { "${pkgs.haskell-language-server}/bin/haskell-language-server" }
                # })
            }
            null-ls-nvim

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

            {
                plugin = gitsigns-nvim;
                type = "lua";
                config = builtins.readFile ./lua/gitsigns.lua;
            }
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
            {
                plugin = trouble-nvim;
                type = "lua";
                config = builtins.readFile ./lua/trouble.lua;
            }
            {
                plugin = todo-comments-nvim;
                type = "lua";
                config = builtins.readFile ./lua/todo-comments.lua;
            }
            {
                plugin = leap-nvim;
                type = "lua";
                config = builtins.readFile ./lua/leap.lua;
            }
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
            {
                plugin = zen-mode-nvim;
                type = "lua";
                config = builtins.readFile ./lua/zen-mode.lua;
            }
            {
                plugin = twilight-nvim;
                type = "lua";
                config = builtins.readFile ./lua/twilight.lua;
            }
            {
                plugin = nvim-highlight-colors;
                type = "lua";
                config = builtins.readFile ./lua/nvim-highlight-colors.lua;
            }
            {
                plugin = nvim-lastplace;
                type = "lua";
                config = builtins.readFile ./lua/nvim-lastplace.lua;
            }
            # {
            #     plugin = kmonad-vim;
            #     type = "lua";
            # }
        ];
    };
}
