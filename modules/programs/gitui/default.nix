{
  flake.modules.homeManager.gitui = _: {
    config = {
      programs = {
        gitui = {
          enable = true;
        };
      };
    };
  };
}
