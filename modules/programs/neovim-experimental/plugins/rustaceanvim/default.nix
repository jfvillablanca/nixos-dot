# rustaceanvim — Rust-analyzer integration. Replaces nvim-lspconfig for
# rust-analyzer + ships its own DAP integration. Lazy on FileType rust.
# rustaceanvim configures rust-analyzer itself; no entry in the lsp-servers
# spine.
{lib, ...}: {
  flake.modules.nvim.rustaceanvim = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.rustaceanvim = {
      enable = lib.mkEnableOption "rustaceanvim" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.rustaceanvim;
      };
    };

    config = lib.mkIf config.nvim.plugins.rustaceanvim.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.rustaceanvim.package;
          # No setup() call — rustaceanvim auto-configures via vim.g.rustaceanvim.
          lazy.ft = ["rust"];
        }
      ];
      nvim.extraPackages = [pkgs.rust-analyzer];
    };
  };
}
