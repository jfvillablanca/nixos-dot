{
  flake.modules.homeManager.zathura = _: {
    config = {
      programs = {
        zathura = {
          enable = true;
          options = {
            selection-clipboard = "clipboard";
          };
        };
      };
    };
  };
}
