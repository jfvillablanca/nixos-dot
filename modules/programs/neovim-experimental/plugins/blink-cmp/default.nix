# blink.cmp — completion engine. Replaces the entire nvim-cmp family
# (nvim-cmp + cmp-buffer + cmp-path + cmp-cmdline + cmp_luasnip + cmp-nvim-lsp +
# cmp-nvim-lua + luasnip + friendly-snippets) with a single plugin. Native
# `vim.snippet` handles snippet expansion if needed.
{lib, ...}: {
  flake.modules.nvim.blink-cmp = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.blink-cmp = {
      enable = lib.mkEnableOption "blink.cmp" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.blink-cmp;
      };
    };

    config = lib.mkIf config.nvim.plugins.blink-cmp.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.blink-cmp.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.event = ["InsertEnter" "CmdlineEnter"];
        }
      ];
    };
  };
}
