{
  flake.modules.homeManager.zoxide = {
    lib,
    config,
    ...
  }: {
    config = {
      programs = {
        zoxide = {
          enable = true;
          enableZshIntegration = true;
        };
      };
    };
  };
}
