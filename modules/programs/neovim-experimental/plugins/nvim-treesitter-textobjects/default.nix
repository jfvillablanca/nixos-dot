# nvim-treesitter-textobjects — treesitter-driven text-object selection
# (vif/vaf/vac, etc). Plugs into nvim-treesitter.configs.setup{} for
# `textobjects`. Path B: highlight is started natively per FileType (see
# lib/treesitter spine), but the textobjects sub-plugin still uses the
# nvim-treesitter.configs entry point.
{lib, ...}: {
  flake.modules.nvim.nvim-treesitter-textobjects = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.nvim-treesitter-textobjects = {
      enable = lib.mkEnableOption "nvim-treesitter-textobjects" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.nvim-treesitter-textobjects;
      };
    };

    config = lib.mkIf config.nvim.plugins.nvim-treesitter-textobjects.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.nvim-treesitter-textobjects.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
        }
      ];
    };
  };
}
