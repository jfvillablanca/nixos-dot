{
  flake.modules.homeManager.atuin = _: {
    config = {
      programs.atuin = {
        enable = true;
      };
    };
  };
}
