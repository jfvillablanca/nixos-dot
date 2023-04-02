{ ... }:
{
  services = {
    picom = {
      enable = true;
      activeOpacity = 0.98;
      inactiveOpacity = 0.7;
      backend = "glx";
      vSync = true;             # had to enable due to some screen tearing

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
