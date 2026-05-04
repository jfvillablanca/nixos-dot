# nvim-treesitter-context — sticky function header. Independent of
# nvim-treesitter.configs (sets up via require("treesitter-context").setup).
{lib, ...}: {
  flake.modules.nvim.nvim-treesitter-context = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.nvim-treesitter-context = {
      enable = lib.mkEnableOption "nvim-treesitter-context" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.nvim-treesitter-context;
      };
    };

    config = lib.mkIf config.nvim.plugins.nvim-treesitter-context.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.nvim-treesitter-context.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.event = ["BufReadPost" "BufNewFile"];
        }
      ];
    };
  };
}
