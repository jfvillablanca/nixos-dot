{
  flake.modules.homeManager.spotify-player = _: {
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
