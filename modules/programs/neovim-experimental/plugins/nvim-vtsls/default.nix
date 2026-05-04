# nvim-vtsls — editor-side glue for the vtsls language server (organize
# imports, file references, etc). The LSP server itself is configured at
# ../../lsp/servers/vtsls/.
{lib, ...}: {
  flake.modules.nvim.nvim-vtsls = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.nvim-vtsls = {
      enable = lib.mkEnableOption "nvim-vtsls" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.nvim-vtsls;
      };
    };

    config = lib.mkIf config.nvim.plugins.nvim-vtsls.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.nvim-vtsls.package;
          # No setup required; the plugin registers commands on load. LSP
          # server config lives in the vtsls server module.
          lazy.ft = ["typescript" "typescriptreact" "javascript" "javascriptreact"];
        }
      ];
    };
  };
}
