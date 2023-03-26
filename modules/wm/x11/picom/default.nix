{ ... }:
{
  services = {
    picom = {
      enable = true;
      activeOpacity = 0.95;
      inactiveOpacity = 0.7;
      backend = "xrender";

      # NOTE: Don't know how to use glx in QEMU/KVM machine
      # settings = {
      #     wintypes = {
      #         normal = { blur-background = true; };
      #     };
      #     blur = {
      #         method = "dual_kawase";
      #         strength = 2;
      #     };
      # };
    };
  };
}
