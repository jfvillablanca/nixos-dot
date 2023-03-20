{ config, pkgs, ... }:
let
    mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
in
{
    home.file.".config/nvim" = {
        source = mkOutOfStoreSymlink ./nvim;
        recursive = true;
    };

    programs = {
        neovim = {
            enable = true;
            package = pkgs.neovim-nightly;
            defaultEditor = true;
            vimAlias = true;
            withNodeJs = true;
            withPython3 = true;

            extraPackages = with pkgs; [
                shfmt
            ];

            plugins = with pkgs.vimPlugins; [
                nvim-lspconfig
                mason-lspconfig-nvim
                mason-nvim
            ];
        };
    };
}
