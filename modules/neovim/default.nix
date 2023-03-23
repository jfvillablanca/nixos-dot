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

        extraLuaConfig = builtins.readFile ./nvim/lua/user/options.lua;

        plugins = with pkgs.vimPlugins; [
            plenary-nvim
            {
                plugin = impatient-nvim;
                type = "lua";
                config = ''
                    local status_ok, impatient = pcall(require,  "impatient")
                    if not status_ok then
                        return
                    end
                    impatient.enable_profile()
                '';
            }

            nvim-lspconfig
            mason-lspconfig-nvim
            mason-nvim
        ];
    };
}
