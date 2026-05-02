{
  flake.modules.homeManager.rofi =
{
  lib,
  config,
  ...
}:
{
  config = {
    programs = {
      rofi = {
        enable = true;
        location = "center";
      };
    };
  };
}
  ;
}
