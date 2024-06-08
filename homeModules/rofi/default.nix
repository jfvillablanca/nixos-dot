{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.rofi;
in {
  options.myHomeModules.rofi = {
    enable =
      lib.mkEnableOption "enables rofi"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      rofi = {
        enable = true;
        location = "center";
      };
    };
  };
}
