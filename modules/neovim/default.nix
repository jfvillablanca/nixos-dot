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

        ./lua/telescope.lua

        ./lua/treesitter.lua

        ./lua/gitsigns.lua

        ./lua/comment.lua

        ./lua/trouble.lua
        ./lua/todo-comments.lua
        ./lua/leap.lua
        ./lua/wilder.lua
        ./lua/zk-nvim.lua
        # ./lua/markdownpreview.lua
        ./lua/zen-mode.lua
        ./lua/twilight.lua
        ./lua/nvim-highlight-colors.lua
        ./lua/nvim-lastplace.lua
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
                '';
                # -- require('lspconfig').bashls.setup({
                # --     cmd = { "${pkgs.bash-language-server}/bin/bash-language-server" }
                # -- })
                # require('lspconfig').tsserver.setup({
                #     cmd = { "${pkgs.tsserver}/bin/tsserver" }
                # })
                # require('lspconfig').tailwindcss.setup({
                #     cmd = { "${pkgs.tailwindcss}/bin/tailwindcss" }
                # })
                # require('lspconfig').rust_analyzer.setup({
                #     cmd = { "${pkgs.rust-analyzer}/bin/rust-analyzer" }
                # })
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
            todo-comments-nvim

            leap-nvim
            wilder-nvim
            zk-nvim
            # markdown-preview-nvim

            zen-mode-nvim
            twilight-nvim
            nvim-highlight-colors
            # kmonad-vim (not a package yet)
            nvim-lastplace
        ];
    };
}
