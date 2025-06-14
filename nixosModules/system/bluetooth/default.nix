{...}: {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = false;
      };
    };
  };
  # NOTE: exec-once 'blueman-applet' in your respective window manager
  services.blueman.enable = true;
}
