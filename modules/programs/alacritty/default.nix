{
  flake.modules.homeManager.alacritty = {
    lib,
    config,
    ...
  }: {
    config = {
      programs = {
        alacritty = {
          enable = true;
          settings = {
            window = {
              padding.x = 5;
              padding.y = 5;
              opacity = 1.0;
            };
          };
        };
      };
    };
  };
}
