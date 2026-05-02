# flake.homeModules option declaration. Each modules/home/<name>.nix sets
# `flake.homeModules.<name>`; mk-system + home-configurations consumers
# append `attrValues config.flake.homeModules` to their home-manager imports
# lists so every ported home module is auto-included.
{lib, ...}: {
  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = {};
    description = "Home-manager modules ported into the dendritic tree.";
  };
}
