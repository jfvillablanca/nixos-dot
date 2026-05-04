{lib, ...}: {
  flake.modules.nvim.trouble = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.trouble = {
      enable = lib.mkEnableOption "trouble-nvim (diagnostics + LSP refs UI)" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.trouble-nvim;
      };
    };

    config = lib.mkIf config.nvim.plugins.trouble.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.trouble.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.cmd = ["Trouble"];
        }
      ];

      nvim.keymaps = [
        {
          mode = "n";
          lhs = "<leader>xx";
          rhs = "<cmd>Trouble diagnostics toggle<cr>";
          desc = "Diagnostics (Trouble)";
          group = "diag";
        }
        {
          mode = "n";
          lhs = "<leader>xX";
          rhs = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
          desc = "Buffer diagnostics (Trouble)";
          group = "diag";
        }
        {
          mode = "n";
          lhs = "<leader>xs";
          rhs = "<cmd>Trouble symbols toggle focus=false<cr>";
          desc = "Symbols (Trouble)";
          group = "diag";
        }
        {
          mode = "n";
          lhs = "<leader>xL";
          rhs = "<cmd>Trouble loclist toggle<cr>";
          desc = "Location list (Trouble)";
          group = "diag";
        }
        {
          mode = "n";
          lhs = "<leader>xQ";
          rhs = "<cmd>Trouble qflist toggle<cr>";
          desc = "Quickfix (Trouble)";
          group = "diag";
        }
      ];
    };
  };
}
