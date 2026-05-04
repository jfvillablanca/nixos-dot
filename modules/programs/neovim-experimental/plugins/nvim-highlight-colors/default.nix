{lib, ...}: {
  flake.modules.nvim.nvim-highlight-colors = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.nvim-highlight-colors = {
      enable = lib.mkEnableOption "nvim-highlight-colors (hex/named/tailwind)" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.nvim-highlight-colors;
      };
    };

    config = lib.mkIf config.nvim.plugins.nvim-highlight-colors.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.nvim-highlight-colors.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.event = ["BufReadPost" "BufNewFile"];
        }
      ];
    };
  };
}
