{lib, ...}: {
  flake.modules.nvim.treesj = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.treesj = {
      enable = lib.mkEnableOption "treesj (split/join)" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.treesj;
      };
    };

    config = lib.mkIf config.nvim.plugins.treesj.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.treesj.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.cmd = ["TSJToggle" "TSJSplit" "TSJJoin"];
        }
      ];
    };
  };
}
