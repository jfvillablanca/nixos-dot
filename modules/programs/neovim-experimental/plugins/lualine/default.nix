# lualine-nvim — statusline. Statusline spine deferred: no current plugin
# dynamically contributes components, so the lualine config is inline. Add
# a `nvim.statusline.components` spine when a contributor exists.
{lib, ...}: {
  flake.modules.nvim.lualine = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.lualine = {
      enable = lib.mkEnableOption "lualine-nvim" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.lualine-nvim;
      };
    };

    config = lib.mkIf config.nvim.plugins.lualine.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.lualine.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.event = ["VeryLazy"];
        }
      ];
    };
  };
}
