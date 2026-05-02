{
  flake.modules.homeManager.ripgrep = _: {
    config = {
      programs.ripgrep = {
        enable = true;
      };
    };
  };
}
