{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.fd;
in {
  options.myHomeModules.fd = {
    enable =
      lib.mkEnableOption "enables fd"
      // {
        default = true;
      };
  };
  config = lib.mkIf cfg.enable {
    programs.fd = {
      enable = true;
    };
  };
}
