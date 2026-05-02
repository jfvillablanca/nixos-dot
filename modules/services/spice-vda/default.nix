{
  flake.modules.nixos.spice-vda = _: {
    services.spice-vdagentd.enable = true;
  };
}
