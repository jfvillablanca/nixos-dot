{
  flake.modules.homeManager.delta =
{
  lib,
  config,
  ...
}:
{
  config = {
    programs = {
      delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          features = "decorations";
          decorations = {
            commit-decoration-style = "#7FB4CA ol";
            commit-style = "raw";
            file-style = "omit";
            hunk-header-decoration-style = "#7FB4CA box";
            hunk-header-file-style = "#E46876";
            hunk-header-line-number-style = "#98BB6C";
            hunk-header-style = "file line-number syntax";
          };
        };
      };
    };
  };
}
  ;
}
