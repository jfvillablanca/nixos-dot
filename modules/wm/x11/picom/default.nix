{ ... }:
{
  services = {
    picom = {
      enable = true;
      activeOpacity = 0.98;
      inactiveOpacity = 0.90;
      backend = "glx";
      vSync = true;             # had to enable due to some screen tearing

      settings = {
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
