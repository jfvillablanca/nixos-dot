{
  flake.modules.homeManager.git = {config, ...}: {
    config = {
      programs = {
        git = {
          enable = true;
          settings = {
            init.defaultBranch = "main";
            user = {
              inherit (config.systemConstants.git) name email;
            };
            color.ui = "auto";
            rerere.enabled = true;
          };
          lfs = {
            enable = true;
          };
        };
      };
    };
  };
}
