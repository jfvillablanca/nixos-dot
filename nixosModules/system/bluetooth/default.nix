{...}: {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
      };
    };
  };
  # NOTE: exec-once 'blueman-applet' in your respective window manager
  services.blueman.enable = true;
}
