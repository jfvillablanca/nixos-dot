# none-ls — formatter/linter/code-action via the LSP protocol. Phase 2 ports
# the existing rigid config 1:1; all tools are pre-baked into extraPackages.
# Project-aware tool selection (via none-ls's `condition` callbacks) deferred
# to Phase 3 along with formatters/linters spines.
{lib, ...}: {
  flake.modules.nvim.none-ls = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.none-ls = {
      enable = lib.mkEnableOption "none-ls" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.none-ls-nvim;
      };
    };

    config = lib.mkIf config.nvim.plugins.none-ls.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.none-ls.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.event = ["BufReadPost" "BufNewFile"];
        }
      ];
      # Tools none-ls invokes at runtime. Match the source list in _config.lua.
      nvim.extraPackages = with pkgs; [
        stylua
        selene
        shfmt
        alejandra
        statix
        deadnix
        leptosfmt
        gofumpt
        actionlint
        clang-tools
        nodePackages.stylelint
        nodePackages.sql-formatter
        python3Packages.isort
        python3Packages.black
      ];
    };
  };
}
