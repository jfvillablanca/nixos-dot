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

            nvim-lspconfig
            mason-nvim
            mason-lspconfig-nvim
            null-ls-nvim
        ];
    };
}
