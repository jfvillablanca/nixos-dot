{...}: {
  xdg.configFile.".wallpapers" = {
    source = ./.;
    recursive = true;
  };
}
