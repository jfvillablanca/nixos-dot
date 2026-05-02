{
  flake.modules.homeManager.direnv = {
    lib,
    config,
    ...
  }: {
    config = {
      programs = {
        direnv = {
          enable = true;
          enableZshIntegration = true;
          nix-direnv.enable = true;
        };
      };
    };
  };
}
