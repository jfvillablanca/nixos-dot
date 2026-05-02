{
  flake.modules.homeManager.zathura =
{
  lib,
  config,
  ...
}:
{

  config = {
    programs = {
      zathura = {
        enable = true;
        options = {
          selection-clipboard = "clipboard";
        };
      };
    };
  };
}
  ;
}
