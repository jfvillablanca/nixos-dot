# which-key-nvim — popup help for keymaps. Acts as the consumer-side renderer
# for the `nvim.keymaps` spine: keymaps are registered via vim.keymap.set with
# `desc` fields by the spine, which-key auto-discovers them via vim.api.nvim_get_keymap
# and renders the popup. Only group prefixes need explicit registration here.
{lib, ...}: {
  flake.modules.nvim.which-key = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.which-key = {
      enable = lib.mkEnableOption "which-key-nvim" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.which-key-nvim;
      };
    };

    config = lib.mkIf config.nvim.plugins.which-key.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.which-key.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.event = ["VeryLazy"];
        }
      ];
    };
  };
}
