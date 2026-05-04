# Conditionally include base16-nvim. When enabled, pair with
# `nvim.colorscheme = "base16-<slug>"` so the wrapper's bootstrap calls
# `vim.cmd.colorscheme("base16-<slug>")`. When disabled (default),
# `nix run .#nvim-experimental` falls back to neovim's bundled default.
#
# All other colorscheme plugins (gruvbox, kanagawa, tokyonight, …) are
# intentionally absent from the experimental tree — colorscheme is a host
# concern delivered via stylix/nix-colors slug, not a per-plugin choice.
_: {
  flake.modules.nvim.colorscheme = {
    config,
    pkgs,
    lib,
    ...
  }: {
    options.nvim.base16-nvim = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Add base16-nvim to the plugin set. Pair with
          `nvim.colorscheme = "base16-<slug>"` to render a stylix/nix-colors
          slug. Default off — standalone runs use neovim's bundled default.
        '';
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.base16-nvim;
        description = "base16-nvim source. Override to swap nixpkgs's pinned rev.";
      };
    };

    config = lib.mkIf config.nvim.base16-nvim.enable {
      nvim.plugins.list = [
        {plugin = config.nvim.base16-nvim.package;}
      ];
    };
  };
}
