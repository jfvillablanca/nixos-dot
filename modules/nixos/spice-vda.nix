{
  flake.modules.nixos.spice-vda =
{...}: {
  services.spice-vdagentd.enable = true;
}
  ;
}
