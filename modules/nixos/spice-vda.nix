{
  flake.nixosModules.spice-vda =
{...}: {
  services.spice-vdagentd.enable = true;
}
  ;
}
