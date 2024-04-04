{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.eww;
in {
  options.myHomeModules.eww = {
    enable =
      lib.mkEnableOption "enables eww"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      eww = {
        enable = true;
        configDir = ./config;
      };
    };
  };
}
