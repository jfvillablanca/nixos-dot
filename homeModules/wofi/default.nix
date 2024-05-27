{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.wofi;
in {
  options.myHomeModules.wofi = {
    enable =
      lib.mkEnableOption "enables wofi"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
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
