{pkgs-stable-24-05, ...}: {
  hardware.bluetooth = {
    enable = true;
    package = pkgs-stable-24-05.bluez;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = false;
        # FastConnectable = true;
      };
      # Policy = {
      #   AutoEnable = true;
      # };
    };
  };
  # NOTE: exec-once 'blueman-applet' in your respective window manager
  services.blueman.enable = true;
}
