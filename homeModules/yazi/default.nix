{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.yazi;
in {
  options.myHomeModules.yazi = {
    enable =
      lib.mkEnableOption "enables yazi"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
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
