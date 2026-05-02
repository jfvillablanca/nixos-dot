{
  flake.modules.homeManager.gitui = {
    lib,
    config,
    ...
  }: {
    config = {
      programs = {
        gitui = {
          enable = true;
        };
      };
    };
  };
}
