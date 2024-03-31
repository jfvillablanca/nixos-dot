{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.picom;
in {
  options.myHomeModules.picom = {
    enable =
      lib.mkEnableOption "enables picom"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    services = {
      picom = {
        enable = true;
        activeOpacity = 1.00;
        inactiveOpacity = 0.90;
        backend = "glx";
        vSync = true; # had to enable due to some screen tearing
        opacityRules = [
          "100:class_g='firefox' && focused"
          "90:class_g='firefox' && !focused"
          "90:class_g='Alacritty' && focused"
          "70:class_g='Alacritty' && !focused"
          "100:name^='steam_app' && focused"
          "100:name^='steam_app' && !focused"
        ];
        settings = {
          # OPACITY (extra rules)
          inactive-opacity-override = false;

          # FADING
          fading = true;
          fade-in-step = 0.04;
          fade-out-step = 0.04;
          fade-delta = 2;
          no-fading-openclose = false;

          # CORNERS
          corner-radius = 10;
          rounded-corners-exclude = [
            "window_type = 'dock'"
          ];

          # BLUR
          blur = {
            method = "dual_kawase";
            strength = 5;
          };

          # WINTYPES
          wintypes = {
            normal = {blur-background = true;};
            tooltip = {
              fade = false;
              shadow = true;
              opacity = 1.0;
              focus = true;
              full-shadow = false;
            };
            dock = {shadow = false;};
            dnd = {shadow = false;};
            popup_menu = {
              opacity = 1.0;
              fade = false;
            };
            dropdown_menu = {
              opacity = 1.0;
              fade = false;
            };
          };
        };
      };
    };
  };
}
