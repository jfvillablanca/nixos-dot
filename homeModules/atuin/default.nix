{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.atuin;
in {
  options.myHomeModules.atuin = {
    enable =
      lib.mkEnableOption "enables atuin"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    programs.atuin = {
      enable = true;
    };
  };
}
