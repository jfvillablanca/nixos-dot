{
  flake.modules.homeManager.zoxide = _: {
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
