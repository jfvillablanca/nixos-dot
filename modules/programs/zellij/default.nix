{
  flake.modules.homeManager.zellij = _: {
    config = {
      xdg.configFile."zellij" = {
        source = ./configs;
        recursive = true;
      };

      programs = {
        zellij = {
          enable = true;
        };
      };
    };
  };
}
