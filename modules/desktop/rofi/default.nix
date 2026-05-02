{
  flake.modules.homeManager.rofi = _: {
    config = {
      programs = {
        rofi = {
          enable = true;
          location = "center";
        };
      };
    };
  };
}
