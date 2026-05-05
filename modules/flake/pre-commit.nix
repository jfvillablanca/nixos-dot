# Pre-commit hooks via cachix/git-hooks.nix.
#
# `nix develop` installs the hook into .git/hooks/pre-commit. From then
# on every `git commit` runs the configured checks: treefmt (whose own
# config lives in modules/flake/treefmt.nix), statix (nix anti-pattern
# linter), and deadnix (dead-code finder). The same checks also run via
# `nix flake check`.
{inputs, ...}: {
  flake-file.inputs.git-hooks-nix = {
    url = "github:cachix/git-hooks.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [inputs.git-hooks-nix.flakeModule];

  perSystem = _: {
    pre-commit = {
      check.enable = true;
      settings.hooks = {
        treefmt.enable = true;
        # statix reads `./statix.toml` for its lint disable list.
        statix.enable = true;
        deadnix = {
          enable = true;
          settings.edit = false;
          # Templates are scaffolding for `nix flake init`; their args
          # are unused by design.
          excludes = ["^templates/"];
        };
      };
    };
  };
}
