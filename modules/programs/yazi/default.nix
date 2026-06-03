{
  flake.modules.homeManager.yazi = _: {
    config = {
      programs = {
        yazi = {
          enable = true;
          enableBashIntegration = true;
          enableFishIntegration = true;
          enableZshIntegration = true;
          shellWrapperName = "yy";
        };
      };
    };
  };
}
