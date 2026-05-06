# nix-index + comma. Replaces our hand-rolled `use` script (which needed
# the attribute name) with `comma`, which resolves a binary name (e.g.,
# `, convert` → imagemagick) by querying a prebuilt nix-index database.
#
# `nix-index-database` ships the prebuilt index, so first run doesn't have
# to spend half an hour building one locally.
{inputs, ...}: {
  flake-file.inputs.nix-index-database = {
    url = "github:nix-community/nix-index-database";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.nix-index = {
    imports = [inputs.nix-index-database.nixosModules.nix-index];

    # Wraps `comma` with the index DB and adds it to environment.systemPackages.
    programs.nix-index-database.comma.enable = true;
  };
}
