# `nix fmt` runs treefmt across the whole tree. Adds:
#   - alejandra for *.nix
#   - stylua for *.lua
#   - shfmt for *.sh
#   - prettier for *.md, *.json, *.yaml, *.yml
{inputs, ...}: {
  imports = [inputs.treefmt-nix.flakeModule];

  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";

      programs = {
        alejandra.enable = true;
        stylua.enable = true;
        shfmt.enable = true;
        prettier.enable = true;
      };
    };
  };
}
