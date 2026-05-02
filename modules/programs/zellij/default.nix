{
  flake.modules.homeManager.zellij =
{
  lib,
  config,
  ...
}:
{
  config = {
    xdg.configFile."zellij" = {
      source = ./configs;
      recursive = true;
    };

    programs = {
      zellij = {
        enable = true;
      };
    };
  };
}
  ;
}
