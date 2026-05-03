# Dev shell + flake templates.
{self, ...}: {
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        stylua
        selene
        lua-language-server

        alejandra
        statix
        deadnix
        nil
        nixd

        # Task runner — see ./justfile for nvim-{baseline,gate,exp,exp-smoke}.
        just
      ];

      # Installs the cachix/git-hooks pre-commit hook on `nix develop`
      # entry. Configured in modules/flake/pre-commit.nix.
      shellHook = config.pre-commit.installationScript;
    };
  };

  flake.templates = let
    basic = {
      path = self + /templates/basic;
      description = "A basic flake with devenv.";
    };
  in {
    inherit basic;
    default = basic;
  };
}
