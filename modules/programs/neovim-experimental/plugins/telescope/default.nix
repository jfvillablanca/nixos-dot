# telescope-nvim — fuzzy picker. The largest config of the Phase 1 plugins;
# proves the spine pattern's ability to host plugins with rich inline lua
# while still emitting cross-cutting keymaps to the spine.
#
# `ripgrep` is added to extraPackages so telescope's vimgrep_arguments
# resolve at runtime regardless of host PATH.
{lib, ...}: {
  flake.modules.nvim.telescope = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.telescope = {
      enable = lib.mkEnableOption "telescope-nvim" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.telescope-nvim;
        description = "telescope-nvim source. Override to swap nixpkgs's pinned rev for upstream HEAD.";
      };
    };

    config = lib.mkIf config.nvim.plugins.telescope.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.telescope.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.cmd = ["Telescope"];
        }
      ];

      nvim.extraPackages = [pkgs.ripgrep];

      nvim.keymaps = [
        {
          mode = "n";
          lhs = "<leader>ff";
          rhs = "<cmd>Telescope find_files<cr>";
          desc = "Find files";
          group = "find";
        }
        {
          mode = "n";
          lhs = "<leader>fg";
          rhs = "<cmd>Telescope live_grep<cr>";
          desc = "Live grep";
          group = "find";
        }
        {
          mode = "n";
          lhs = "<leader>fb";
          rhs = "<cmd>Telescope buffers<cr>";
          desc = "Buffers";
          group = "find";
        }
        {
          mode = "n";
          lhs = "<leader>fh";
          rhs = "<cmd>Telescope help_tags<cr>";
          desc = "Help tags";
          group = "find";
        }
        {
          mode = "n";
          lhs = "<leader>fr";
          rhs = "<cmd>Telescope resume<cr>";
          desc = "Resume last picker";
          group = "find";
        }
      ];
    };
  };
}
