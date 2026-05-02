{
  flake.modules.homeManager.ripgrep =
{
  lib,
  config,
  ...
}:
{
  config = {
    programs.ripgrep = {
      enable = true;
    };
  };
}
  ;
}
