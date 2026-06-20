{
  inputs,
  self,
  ...
}: let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

  hostConsts = host: inputs.self.nixosConfigurations.${host}.config.systemConstants;
  hostHome = host: inputs.self.nixosConfigurations.${host}.config.home-manager.users.${(hostConsts host).user};

  nixdOptionsFor = host: let
    inherit (hostConsts host) user repoPath;
  in {
    nixos.expr = ''(builtins.getFlake "${repoPath}").nixosConfigurations."${host}".options'';
    home_manager.expr = ''(builtins.getFlake "${repoPath}").nixosConfigurations."${host}".config.home-manager.users.${user}'';
    flake_parts.expr = ''(builtins.getFlake "${repoPath}").debug.options'';
    nvim.expr = ''(builtins.getFlake "${repoPath}").nvimOptions'';
  };
in {
  flake.packages.x86_64-linux = {
    nvim = (hostHome "cimmerian").programs.neovim.finalPackage;

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
          nvim.lsp.servers.nixd.settings.nixd.options = nixdOptionsFor "cimmerian";
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
          nvim.lsp.servers.nixd.settings.nixd.options = nixdOptionsFor "t14g1";
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

    flake-delta = pkgs.callPackage (self + /packages/by-name/f/flake-delta) {};
  };
}
