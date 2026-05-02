{
  flake.modules.homeManager.eza = _: {
    config = {
      programs = {
        eza = {
          enable = true;
          git = true;
          icons = "auto";
          extraOptions = [
            "--group-directories-first"
          ];
        };
      };
    };
  };
}
