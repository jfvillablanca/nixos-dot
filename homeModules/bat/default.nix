{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.bat;
in {
  options.myHomeModules.bat = {
    enable =
      lib.mkEnableOption "enables bat"
      // {
        default = true;
      };
  };
  config = lib.mkIf cfg.enable {
    programs.bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [
        batgrep
      ];
    };
  };
}
