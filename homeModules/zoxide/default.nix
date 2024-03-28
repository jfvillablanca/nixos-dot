{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.zoxide;
in {
  options.myHomeModules.zoxide = {
    enable =
      lib.mkEnableOption "enables zoxide"
      // {
        default = true;
      };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      zoxide = {
        enable = true;
        enableZshIntegration = true;
      };
    };
  };
}
