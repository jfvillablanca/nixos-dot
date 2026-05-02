{
  flake.modules.nixos.virtual-fs = _: {
    # Virtual filesystem support
    services.gvfs.enable = true;
  };
}
