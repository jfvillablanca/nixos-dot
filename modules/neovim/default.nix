{ config, pkgs, ... }:
let
    luaConfig = [
        ./lua/impatient.lua
        ./lua/options.lua
        ./lua/keymaps.lua

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

        # ./lua/treesitter.lua

        ./lua/gitsigns.lua

        ./lua/comment.lua
    ];
in
{
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
            nvim-lspconfig
            mason-nvim
            mason-lspconfig-nvim
            null-ls-nvim

            # Telescope
            telescope-nvim
            telescope-fzf-native-nvim
            
            # Treesitter
            # nvim-treesitter.withAllGrammars

            gitsigns-nvim

            comment-nvim
            # nvim-ts-context-commentstring
        ];
    };
}
