{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.ripgrep;
in {
  options.myHomeModules.ripgrep = {
    enable =
      lib.mkEnableOption "enables ripgrep"
      // {
        default = true;
      };
  };
  config = lib.mkIf cfg.enable {
    programs.ripgrep = {
      enable = true;
    };
  };
}
