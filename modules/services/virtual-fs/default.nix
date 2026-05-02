{
  flake.modules.nixos.virtual-fs =
{...}: {
  # Virtual filesystem support
  services.gvfs.enable = true;
}
  ;
}
