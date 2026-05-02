{
  flake.modules.homeManager.gh =
{
  lib,
  config,
  ...
}:
{
  config = {
    programs = {
      gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
        };
      };
      gh-dash = {
        enable = true;
      };
    };
  };
}
  ;
}
