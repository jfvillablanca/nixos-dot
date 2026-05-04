{lib, ...}: {
  flake.modules.nvim.indent-blankline = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.indent-blankline = {
      enable = lib.mkEnableOption "indent-blankline-nvim (ibl)" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.indent-blankline-nvim;
      };
    };

    config = lib.mkIf config.nvim.plugins.indent-blankline.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.indent-blankline.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.event = ["BufReadPost" "BufNewFile"];
        }
      ];
    };
  };
}
