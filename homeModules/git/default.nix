{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.git;
in {
  options.myHomeModules.git = {
    enable =
      lib.mkEnableOption "enables git in user land"
      // {
        default = true;
      };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      git = {
        enable = true;
        extraConfig = {
          init.defaultBranch = "main";
          user = {
            name = "jfvillablanca";
            email = "31008330+jfvillablanca@users.noreply.github.com";
          };
          color.ui = "auto";
          rerere.enabled = true;
        };
        delta = {
          enable = true;
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
  };
}
