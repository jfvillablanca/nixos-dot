{
  flake.modules.homeManager.eww =
{
  lib,
  config,
  ...
}:
{
  config = {
    programs = {
      eww = {
        enable = true;
        configDir = ./config;
      };
    };
  };
}
  ;
}
