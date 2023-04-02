{ ... }:
{
  services = {
    picom = {
      enable = true;
      activeOpacity = 0.98;
      inactiveOpacity = 0.7;
      backend = "glx";

      settings = {
          wintypes = {
              normal = { blur-background = true; };
          };
          blur = {
              method = "dual_kawase";
              strength = 2;
          };
      };
    };
  };
}
