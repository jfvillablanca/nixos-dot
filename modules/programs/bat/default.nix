{
  flake.modules.homeManager.bat =
{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = {
    programs.bat = {
      enable = true;
      # extraPackages = with pkgs.bat-extras; [];
    };
  };
}
  ;
}
