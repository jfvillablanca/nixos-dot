{
  flake.modules.homeManager.fd =
{
  lib,
  config,
  ...
}:
{
  config = {
    programs.fd = {
      enable = true;
    };
  };
}
  ;
}
