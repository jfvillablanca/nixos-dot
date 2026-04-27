{
  flake.nixosModules.virtual-fs =
{...}: {
  # Virtual filesystem support
  services.gvfs.enable = true;
}
  ;
}
