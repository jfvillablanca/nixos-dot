{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.zathura;
in {
  options.myHomeModules.zathura = {
    enable = lib.mkEnableOption "enables zathura";
  };

  config = lib.mkIf cfg.enable {
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
