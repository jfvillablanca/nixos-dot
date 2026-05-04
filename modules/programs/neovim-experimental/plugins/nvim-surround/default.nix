{lib, ...}: {
  flake.modules.nvim.nvim-surround = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.nvim-surround = {
      enable = lib.mkEnableOption "nvim-surround" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.nvim-surround;
      };
    };

    config = lib.mkIf config.nvim.plugins.nvim-surround.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.nvim-surround.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
        }
      ];
    };
  };
}
