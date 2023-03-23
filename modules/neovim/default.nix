{ config, pkgs, ... }:
let
    luaConfig = [
        ./lua/impatient.lua
        ./lua/options.lua
        ./lua/keymaps.lua
        ./lua/autocommands.lua

        ./lua/nvim-tree.lua
        ./lua/lualine.lua
        ./lua/toggleterm.lua
        ./lua/indentline.lua
        ./lua/whichkey.lua
            ./lua/colorschemes/rosepine.lua
            ./lua/colorschemes/kanagawa.lua
        ./lua/colorscheme.lua
        
        ./lua/cmp.lua

        ./lua/lsp/lsp.lua
        ./lua/lsp/null-ls.lua
        # ./lua/typescript-nvim.lua -- need to package 

        ./lua/telescope.lua

        ./lua/treesitter.lua

        ./lua/gitsigns.lua

        ./lua/comment.lua

        ./lua/trouble.lua
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
            nvim-tree-lua
            lualine-nvim
            toggleterm-nvim
            indent-blankline-nvim
            which-key-nvim

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
            telescope-nvim
            telescope-fzf-native-nvim
            
            # Treesitter
            nvim-treesitter.withAllGrammars

            gitsigns-nvim

            comment-nvim
            # nvim-ts-context-commentstring

            trouble-nvim
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
