{
  flake.modules.homeManager.spotify-player = {
    lib,
    config,
    ...
  }: {
    config = {
      programs = {
        spotify-player = {
          enable = true;
          keymaps = [
            {
              command = "None";
              key_sequence = "q";
            }
          ];
        };
      };
    };
  };
}
