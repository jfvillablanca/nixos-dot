# nixd — nix language server. Default on; cimmerian uses it as primary.
# NixOS options expansion (`settings.nixd.options.{nixos,home_manager}.expr`)
# is host-specific and lives at the factory call site (modules/flake/packages.nix)
# rather than here, so the standalone `.#nvim-experimental` doesn't bake in
# any user's flake path.
{lib, ...}: {
  flake.modules.nvim.lsp-nixd = {pkgs, ...}: {
    nvim.lsp.servers.nixd = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.nixd;
      cmd = ["${lib.getExe pkgs.nixd}"];
      filetypes = ["nix"];
      root_markers = ["flake.nix" ".git"];
      settings.nixd = {
        nixpkgs.expr = "import <nixpkgs> { }";
        formatting.command = ["alejandra"];
      };
    };

    # Defer formatting to none-ls (alejandra via the formatters spine).
    nvim.lsp.formatProviderDisable = ["nixd"];
  };
}
