{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.autorandr;
in {
  options.myHomeModules.autorandr = {
    enable =
      lib.mkEnableOption "enables autorandr"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    programs.autorandr = {
      enable = true;
    };
    services.autorandr = {
      enable = true;
    };
  };
}
