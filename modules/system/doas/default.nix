{
  flake.modules.nixos.doas = _: {
    security.doas.enable = true;
  };
}
