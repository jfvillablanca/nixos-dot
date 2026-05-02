{
  flake.modules.homeManager.autorandr = {
    lib,
    config,
    ...
  }: {
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
