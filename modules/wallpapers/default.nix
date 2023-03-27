{ ... }: {
  xdg.configFile.".wallpapers" = {
    source = ../../.wallpapers;
    recursive = true;
  };
}
