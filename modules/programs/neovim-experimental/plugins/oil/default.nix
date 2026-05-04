# oil-nvim — buffer-based file navigator. The single trivial Simple Aspect
# plugin we use to prove the per-plugin module shape end-to-end.
{lib, ...}: {
  flake.modules.nvim.oil = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.oil = {
      enable = lib.mkEnableOption "oil-nvim file navigator" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.oil-nvim;
        description = "oil-nvim source. Override to swap nixpkgs's pinned rev for upstream HEAD.";
      };
    };

    config = lib.mkIf config.nvim.plugins.oil.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.oil.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
        }
      ];

      nvim.keymaps = [
        {
          mode = "n";
          lhs = "-";
          rhs = "<cmd>Oil<cr>";
          desc = "Open parent directory (oil)";
          group = "files";
        }
      ];
    };
  };
}
