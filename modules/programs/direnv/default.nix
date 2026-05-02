{
  flake.modules.homeManager.direnv = _: {
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
