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
    };
  };
}
