{
  flake.modules.homeManager.eww = _: {
    config = {
      programs = {
        eww = {
          enable = true;
          configDir = ./config;
        };
      };
    };
  };
}
