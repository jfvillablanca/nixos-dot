{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.wofi;
in {
  options.myHomeModules.wofi = {
    enable =
      lib.mkEnableOption "enables wofi"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      wofi = {
        enable = true;
        style = ''
          * {
            font-family: JetBrainsMono Nerd Font 13
          }
          window {
              background-color: #7c818c;
          }
        '';
        settings = {
          location = "center";
        };
      };
    };
  };
}
