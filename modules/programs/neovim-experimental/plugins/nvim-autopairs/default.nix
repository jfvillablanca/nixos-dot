{lib, ...}: {
  flake.modules.nvim.nvim-autopairs = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.nvim-autopairs = {
      enable = lib.mkEnableOption "nvim-autopairs" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.nvim-autopairs;
      };
    };

    config = lib.mkIf config.nvim.plugins.nvim-autopairs.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.nvim-autopairs.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.event = ["InsertEnter"];
        }
      ];
    };
  };
}
