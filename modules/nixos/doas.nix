{
  flake.nixosModules.doas = {...}: {
    security.doas.enable = true;
  };
}
