# gitsigns-nvim — gutter signs + hunk operations. The spine contributor that
# proves cross-cutting concerns: contributes its hunk-navigation keymaps to
# `nvim.keymaps` (consumed by which-key in Phase 2; vim.keymap.set today).
{lib, ...}: {
  flake.modules.nvim.gitsigns = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.gitsigns = {
      enable = lib.mkEnableOption "gitsigns-nvim" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.gitsigns-nvim;
        description = "gitsigns-nvim source. Override to swap nixpkgs's pinned rev for upstream HEAD.";
      };
    };

    config = lib.mkIf config.nvim.plugins.gitsigns.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.gitsigns.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.event = ["BufReadPre" "BufNewFile"];
        }
      ];

      nvim.keymaps = [
        {
          mode = "n";
          lhs = "]c";
          rhs = "<cmd>Gitsigns next_hunk<cr>";
          desc = "Next git hunk";
          group = "git";
        }
        {
          mode = "n";
          lhs = "[c";
          rhs = "<cmd>Gitsigns prev_hunk<cr>";
          desc = "Prev git hunk";
          group = "git";
        }
        {
          mode = "n";
          lhs = "<leader>hp";
          rhs = "<cmd>Gitsigns preview_hunk<cr>";
          desc = "Preview git hunk";
          group = "git";
        }
        {
          mode = "n";
          lhs = "<leader>hb";
          rhs = "<cmd>Gitsigns blame_line<cr>";
          desc = "Blame current line";
          group = "git";
        }
        {
          mode = "n";
          lhs = "<leader>hs";
          rhs = "<cmd>Gitsigns stage_hunk<cr>";
          desc = "Stage hunk";
          group = "git";
        }
        {
          mode = "n";
          lhs = "<leader>hr";
          rhs = "<cmd>Gitsigns reset_hunk<cr>";
          desc = "Reset hunk";
          group = "git";
        }
      ];
    };
  };
}
