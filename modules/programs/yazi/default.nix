{
  flake.modules.homeManager.yazi =
{
  lib,
  config,
  ...
}:
{
  config = {
    programs = {
      yazi = {
        enable = true;
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = true;
      };
    };
  };
}
  ;
}
