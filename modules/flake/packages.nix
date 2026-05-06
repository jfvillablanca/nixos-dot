{
  inputs,
  self,
  ...
}: let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
in {
  flake.packages.x86_64-linux = {
    nvim = inputs.self.nixosConfigurations.cimmerian.config.home-manager.users.jmfv.programs.neovim.finalPackage;

    # nixd's NixOS options expansion is host-specific (it embeds the flake's
    # local checkout path and the host name). Lives at the factory call site
    # rather than the server module so the standalone `.#nvim-experimental`
    # doesn't bake in any user's flake path.
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
          nvim.lsp.servers.nixd.settings.nixd.options = {
            nixos.expr = ''(builtins.getFlake "/home/jmfv/nixos-dot").nixosConfigurations."cimmerian".options'';
            home_manager.expr = ''(builtins.getFlake "/home/jmfv/nixos-dot").nixosConfigurations."cimmerian".config.home-manager.users.jmfv'';
            flake_parts.expr = ''(builtins.getFlake "/home/jmfv/nixos-dot").debug.options'';
          };
        }
      ];
    };

    nvim-experimental-t14g1 = self.factory.nvim {
      system = "x86_64-linux";
      colorscheme = "base16-gruvbox-dark-hard";
      base16 = true;
      markdownPreviewEnable = true;
      debugEnable = true;
      extraModules = [
        {
          nvim.lsp.servers.eslint.enable = true;
          nvim.lsp.servers.texlab.enable = true;
          nvim.lsp.servers.nixd.settings.nixd.options = {
            nixos.expr = ''(builtins.getFlake "/home/jmfv/nixos-dot").nixosConfigurations."t14g1".options'';
            home_manager.expr = ''(builtins.getFlake "/home/jmfv/nixos-dot").nixosConfigurations."t14g1".config.home-manager.users.jmfv'';
            flake_parts.expr = ''(builtins.getFlake "/home/jmfv/nixos-dot").debug.options'';
          };
        }
      ];
    };

    vimx = pkgs.writeShellApplication {
      name = "vimx";
      runtimeInputs = [self.packages.x86_64-linux.nvim-experimental-cimmerian];
      text = ''
        exec nvim "$@"
      '';
    };
  };
}
