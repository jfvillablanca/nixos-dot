{lib, ...}: {
  flake.modules.nvim.nvim-ts-autotag = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.nvim-ts-autotag = {
      enable = lib.mkEnableOption "nvim-ts-autotag (HTML/JSX autoclose)" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.nvim-ts-autotag;
      };
    };

    config = lib.mkIf config.nvim.plugins.nvim-ts-autotag.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.nvim-ts-autotag.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
        }
      ];
    };
  };
}
