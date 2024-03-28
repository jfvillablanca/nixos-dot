{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.zellij;
in {
  options.myHomeModules.zellij = {
    enable =
      lib.mkEnableOption "enables zellij"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    xdg.configFile."zellij" = {
      source = ./configs;
      recursive = true;
    };

    programs = {
      zellij = {
        enable = true;
      };
    };
  };
}
