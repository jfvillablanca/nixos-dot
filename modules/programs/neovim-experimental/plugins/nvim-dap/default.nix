# nvim-dap — debug adapter protocol. Gated behind `nvim.tools.debug.enable`
# (default off). DAP adapters add ~150MB+ to the closure (codelldb,
# vscode-js-debug); not worth it for a foreign-host run that only edits.
{lib, ...}: {
  flake.modules.nvim.nvim-dap = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.nvim-dap = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.nvim-dap;
      };
    };

    config = lib.mkIf config.nvim.tools.debug.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.nvim-dap.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.cmd = ["DapToggleBreakpoint" "DapContinue"];
        }
      ];

      nvim.extraPackages = [
        # Rust DAP
        pkgs.vscode-extensions.vadimcn.vscode-lldb.adapter
        # JS/TS DAP
        pkgs.vscode-js-debug
      ];

      nvim.keymaps = [
        {
          mode = "n";
          lhs = "<leader>bb";
          rhs = "<cmd>lua require('dap').toggle_breakpoint()<cr>";
          desc = "Toggle breakpoint";
          group = "debug";
        }
        {
          mode = "n";
          lhs = "<leader>bc";
          rhs = "<cmd>lua require('dap').continue()<cr>";
          desc = "Continue";
          group = "debug";
        }
        {
          mode = "n";
          lhs = "<leader>bo";
          rhs = "<cmd>lua require('dap').repl.open()<cr>";
          desc = "Open REPL";
          group = "debug";
        }
        {
          mode = "n";
          lhs = "<leader>bk";
          rhs = "<cmd>lua require('dap').terminate()<cr>";
          desc = "Terminate";
          group = "debug";
        }
        {
          mode = "n";
          lhs = "<leader>bso";
          rhs = "<cmd>lua require('dap').step_over()<cr>";
          desc = "Step over";
          group = "debug";
        }
        {
          mode = "n";
          lhs = "<leader>bsi";
          rhs = "<cmd>lua require('dap').step_into()<cr>";
          desc = "Step into";
          group = "debug";
        }
        {
          mode = "n";
          lhs = "<leader>bsu";
          rhs = "<cmd>lua require('dap').step_out()<cr>";
          desc = "Step out";
          group = "debug";
        }
        {
          mode = "n";
          lhs = "<leader>bl";
          rhs = "<cmd>lua require('dap').run_last()<cr>";
          desc = "Run last";
          group = "debug";
        }
      ];
    };
  };
}
