{
  flake.modules.homeManager.autorandr = _: {
    config = {
      programs.autorandr = {
        enable = true;
      };
      services.autorandr = {
        enable = true;
      };
    };
  };
}
