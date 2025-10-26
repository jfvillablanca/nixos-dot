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
        lfs = {
          enable = true;
        };
      };
    };
  };
}
