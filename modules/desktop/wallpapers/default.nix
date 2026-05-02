{
  flake.modules.homeManager.wallpapers = {
    lib,
    config,
    ...
  }:
  {
    config = {
      xdg.configFile.".wallpapers" = {
        source = ./.;
        recursive = true;
      };
    };
  };
}
