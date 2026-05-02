{
  flake.modules.homeManager.wofi =
{
  lib,
  config,
  ...
}:
{
  config = {
    programs = {
      wofi = {
        enable = true;
        settings = {
          width = "50%";
          height = "40%";
          location = "center";
          hide_scroll = true;
          insensitive = true;
          prompt = "";
          no_actions = true;
        };
      };
    };
  };
}
  ;
}
