# Pinned to upstream HEAD via `flake-file.inputs.plugin-oil-nvim`.
{lib, ...}: {
  flake-file.inputs.plugin-oil-nvim = {
    url = "github:stevearc/oil.nvim";
    flake = false;
  };

  flake.modules.nvim.oil = {
    config,
    inputs,
    pkgs,
    ...
  }: {
    options.nvim.plugins.oil = {
      enable = lib.mkEnableOption "oil-nvim file navigator" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimUtils.buildVimPlugin {
          pname = "oil-nvim";
          version = "upstream-${inputs.plugin-oil-nvim.shortRev or "head"}";
          src = inputs.plugin-oil-nvim;
        };
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
