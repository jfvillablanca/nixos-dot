{
  flake.modules.homeManager.wallpapers = _: {
    config = {
      xdg.configFile.".wallpapers" = {
        source = ./.;
        recursive = true;
      };
    };
  };
}
