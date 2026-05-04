# go-nvim — Go-specific UX (test runner, struct tags, etc). Lazy on
# FileType go. Adds gopls to extraPackages so go-nvim can talk to it.
{lib, ...}: {
  flake.modules.nvim.go-nvim = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.go-nvim = {
      enable = lib.mkEnableOption "go-nvim" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.go-nvim;
      };
    };

    config = lib.mkIf config.nvim.plugins.go-nvim.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.go-nvim.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.ft = ["go" "gomod" "gosum"];
        }
      ];
      nvim.extraPackages = [pkgs.gopls pkgs.go];
    };
  };
}
