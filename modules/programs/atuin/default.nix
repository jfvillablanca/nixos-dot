{
  flake.modules.homeManager.atuin = {
    lib,
    config,
    ...
  }: {
    config = {
      programs.atuin = {
        enable = true;
      };
    };
  };
}
