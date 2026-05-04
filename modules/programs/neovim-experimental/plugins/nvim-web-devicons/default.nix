{lib, ...}: {
  flake.modules.nvim.nvim-web-devicons = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.nvim-web-devicons = {
      enable = lib.mkEnableOption "nvim-web-devicons (file icons)" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.nvim-web-devicons;
      };
    };

    config = lib.mkIf config.nvim.plugins.nvim-web-devicons.enable {
      # Auto-loaded by consumers (telescope, lualine, trouble); no setup() required.
      nvim.plugins.list = [
        {plugin = config.nvim.plugins.nvim-web-devicons.package;}
      ];
    };
  };
}
