{ pkgs, ... }:
{
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
