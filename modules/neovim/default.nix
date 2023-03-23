{ config, pkgs, ... }:
let
    luaConfig = [
        ./lua/impatient.lua
        ./lua/options.lua
        ./lua/keymaps.lua

        ./lua/nvim-tree.lua
        ./lua/lualine.lua
        ./lua/toggleterm.lua
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

            nvim-lspconfig
            mason-lspconfig-nvim
            mason-nvim
        ];
    };
}
