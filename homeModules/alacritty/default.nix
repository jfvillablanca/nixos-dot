{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.alacritty;
in {
  options.myHomeModules.alacritty = {
    enable =
      lib.mkEnableOption "enables alacritty"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      alacritty = {
        enable = true;
        settings = {
          window = {
            padding.x = 5;
            padding.y = 5;
            opacity = 1.0;
          };
        };
      };
    };
  };
}
