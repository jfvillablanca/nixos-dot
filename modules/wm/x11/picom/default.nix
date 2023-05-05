_:
{
  services = {
    picom = {
      enable = true;
      activeOpacity = 0.98;
      inactiveOpacity = 0.90;
      backend = "glx";
      vSync = true;             # had to enable due to some screen tearing
      opacityRules = [
        "100:class_g='firefox' && focused"
        "90:class_g='firefox' && !focused"
        "90:class_g='Alacritty' && focused"
        "70:class_g='Alacritty' && !focused"
        "100:name^='steam_app' && focused"
        "100:name^='steam_app' && !focused"
      ];
      settings = {
        inactive-opacity-override = false;
        wintypes = {
          normal = { blur-background = true; };
          tooltip = {
            fade = false;
            shadow = true;
            opacity = 1.0;
            focus = true;
            full-shadow = false;
          };
          dock = { shadow = false; };
          dnd = { shadow = false; };
          popup_menu = {
            opacity = 1.0;
            fade = false;
          };
          dropdown_menu = {
            opacity = 1.0;
            fade = false;
          };
        };
        blur = {
          method = "dual_kawase";
          strength = 2;
        };
      };
    };
  };
}
