{lib, ...}: {
  flake.modules.nvim.refactoring = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.refactoring = {
      enable = lib.mkEnableOption "refactoring-nvim" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.refactoring-nvim;
      };
    };

    config = lib.mkIf config.nvim.plugins.refactoring.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.refactoring.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.event = ["BufReadPost"];
        }
      ];
    };
  };
}
