{lib, ...}: {
  flake.modules.nvim.todo-comments = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.todo-comments = {
      enable = lib.mkEnableOption "todo-comments-nvim" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.todo-comments-nvim;
      };
    };

    config = lib.mkIf config.nvim.plugins.todo-comments.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.todo-comments.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.event = ["BufReadPost" "BufNewFile"];
        }
      ];
      nvim.extraPackages = [pkgs.ripgrep];
    };
  };
}
