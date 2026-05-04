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

      nvim.keymaps = let
        dropdown = name: "<cmd>lua require('telescope.builtin').${name}(require('telescope.themes').get_dropdown({previewer = false}))<cr>";
      in [
        # Top-level shortcuts (outside the <leader>t group).
        {
          mode = "n";
          lhs = "<leader>/";
          rhs = "<cmd>Telescope live_grep<cr>";
          desc = "Find text";
        }
        {
          mode = "n";
          lhs = "<leader><space>";
          rhs = "<cmd>Telescope buffers<cr>";
          desc = "Buffers";
        }

        # <leader>t group.
        {
          mode = "n";
          lhs = "<leader>tf";
          rhs = dropdown "find_files";
          desc = "Find files";
          group = "telescope";
        }
        {
          mode = "n";
          lhs = "<leader>th";
          rhs = dropdown "help_tags";
          desc = "Find help";
          group = "telescope";
        }
        {
          mode = "n";
          lhs = "<leader>tb";
          rhs = "<cmd>Telescope git_branches<cr>";
          desc = "Checkout branch";
          group = "telescope";
        }
        {
          mode = "n";
          lhs = "<leader>tc";
          rhs = "<cmd>Telescope git_commits<cr>";
          desc = "Checkout commit";
          group = "telescope";
        }
        {
          mode = "n";
          lhs = "<leader>tC";
          rhs = "<cmd>Telescope commands<cr>";
          desc = "Commands";
          group = "telescope";
        }
        {
          mode = "n";
          lhs = "<leader>tR";
          rhs = "<cmd>Telescope registers<cr>";
          desc = "Registers";
          group = "telescope";
        }
        {
          mode = "n";
          lhs = "<leader>tk";
          rhs = "<cmd>Telescope keymaps<cr>";
          desc = "Keymaps";
          group = "telescope";
        }
        {
          mode = "n";
          lhs = "<leader>to";
          rhs = "<cmd>Telescope git_status<cr>";
          desc = "Open changed file";
          group = "telescope";
        }
        {
          mode = "n";
          lhs = "<leader>tr";
          rhs = "<cmd>Telescope oldfiles<cr>";
          desc = "Recent files";
          group = "telescope";
        }
        {
          mode = "n";
          lhs = "<leader>tw";
          rhs = "<cmd>Telescope grep_string<cr>";
          desc = "Search current word";
          group = "telescope";
        }
      ];
    };
  };
}
