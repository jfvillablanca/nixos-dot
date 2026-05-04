{lib, ...}: {
  flake.modules.nvim.flash-nvim = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.flash-nvim = {
      enable = lib.mkEnableOption "flash-nvim (jump motions)" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.flash-nvim;
      };
    };

    config = lib.mkIf config.nvim.plugins.flash-nvim.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.flash-nvim.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.event = ["VeryLazy"];
        }
      ];

      nvim.keymaps = [
        {
          mode = ["n" "x" "o"];
          lhs = "s";
          rhs = "<cmd>lua require('flash').jump()<cr>";
          desc = "Flash jump";
          group = "flash";
        }
        {
          mode = ["n" "x" "o"];
          lhs = "S";
          rhs = "<cmd>lua require('flash').treesitter()<cr>";
          desc = "Flash treesitter";
          group = "flash";
        }
        {
          mode = ["o"];
          lhs = "r";
          rhs = "<cmd>lua require('flash').remote()<cr>";
          desc = "Remote flash";
          group = "flash";
        }
        {
          mode = ["o" "x"];
          lhs = "R";
          rhs = "<cmd>lua require('flash').treesitter_search()<cr>";
          desc = "Treesitter search";
          group = "flash";
        }
      ];
    };
  };
}
