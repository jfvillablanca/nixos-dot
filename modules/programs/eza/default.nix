{
  flake.modules.homeManager.eza = {
    lib,
    config,
    ...
  }:
  {
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
