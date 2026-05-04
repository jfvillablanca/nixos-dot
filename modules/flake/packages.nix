# Standalone-runnable packages.
#
# - `.#nvim` re-exports cimmerian's wrapped neovim from its home-manager eval.
#   Daily driver. NVD-gated against a baseline during the experimental rewrite.
# - `.#nvim-experimental` is the standalone variant with no host inference
#   (defined in modules/programs/neovim-experimental/default.nix via the factory).
# - `.#nvim-experimental-<host>` calls `flake.factory.nvim` with the host's
#   stylix slug + tool gates so `nix run .#nvim-experimental-cimmerian` looks
#   like cimmerian's daily driver in colorscheme + enabled tools, but uses the
#   experimental plugin set.
{
  inputs,
  self,
  ...
}: {
  flake.packages.x86_64-linux = {
    nvim = inputs.self.nixosConfigurations.cimmerian.config.home-manager.users.jmfv.programs.neovim.finalPackage;

    nvim-experimental-cimmerian = self.factory.nvim {
      system = "x86_64-linux";
      colorscheme = "base16-spaceduck";
      base16 = true;
      markdownPreviewEnable = true;
      debugEnable = true;
      extraModules = [
        {
          nvim.lsp.servers.eslint.enable = true;
          nvim.lsp.servers.texlab.enable = true;
        }
      ];
    };
  };
}
