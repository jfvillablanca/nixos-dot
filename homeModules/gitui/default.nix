{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.gitui;
in {
  options.myHomeModules.gitui = {
    enable =
      lib.mkEnableOption "enables gitui"
      // {
        default = true;
      };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      gitui = {
        enable = true;
      };
    };
  };
}
