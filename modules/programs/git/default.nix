{
  flake.modules.homeManager.git =
{
  lib,
  config,
  ...
}:
{
  config = {
    programs = {
      git = {
        enable = true;
        settings = {
          init.defaultBranch = "main";
          user = {
            name = "jfvillablanca";
            email = "31008330+jfvillablanca@users.noreply.github.com";
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
}
  ;
}
