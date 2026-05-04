{lib, ...}: {
  flake.modules.nvim.vim-fugitive = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.vim-fugitive = {
      enable = lib.mkEnableOption "vim-fugitive (git porcelain)" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.vim-fugitive;
      };
    };

    config = lib.mkIf config.nvim.plugins.vim-fugitive.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.vim-fugitive.package;
          # No setup; fugitive registers commands on plugin load.
          lazy.cmd = ["G" "Git" "Gdiffsplit" "Gread" "Gwrite" "Glog"];
        }
      ];

      # Merge-conflict resolution: pick from the merge branch (//3) or the
      # target branch (//2) inside a 3-way diff view.
      nvim.keymaps = [
        {
          mode = "n";
          lhs = "<leader>gn";
          rhs = "<cmd>diffget //3<cr>";
          desc = "Diffget from merge branch";
          group = "git";
        }
        {
          mode = "n";
          lhs = "<leader>gt";
          rhs = "<cmd>diffget //2<cr>";
          desc = "Diffget from target branch";
          group = "git";
        }
      ];
    };
  };
}
