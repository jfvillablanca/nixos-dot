# Standalone-runnable packages.
#
{inputs, ...}: {
  flake.packages.x86_64-linux.nvim =
    inputs.self.nixosConfigurations.cimmerian.config.home-manager.users.jmfv.programs.neovim.finalPackage;
}
