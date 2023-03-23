{ config, pkgs, ... }:
let
    luaConfig = [
        ./lua/impatient.lua
        ./lua/options.lua
        ./lua/keymaps.lua
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

            nvim-lspconfig
            mason-lspconfig-nvim
            mason-nvim
        ];
    };
}
