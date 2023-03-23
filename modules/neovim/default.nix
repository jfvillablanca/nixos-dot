{ config, pkgs, ... }:
{
    programs.neovim = {
        enable = true;
        package = pkgs.neovim-nightly;
        defaultEditor = true;
        vimAlias = true;
        withNodeJs = true;
        withPython3 = true;
        withRuby = true;

        extraLuaConfig = builtins.readFile ./lua/options.lua;

        plugins = with pkgs.vimPlugins; [
            plenary-nvim
            {
                plugin = impatient-nvim;
                type = "lua";
                config = builtins.readFile ./lua/impatient.lua;
            }

            nvim-lspconfig
            mason-lspconfig-nvim
            mason-nvim
        ];
    };
}
