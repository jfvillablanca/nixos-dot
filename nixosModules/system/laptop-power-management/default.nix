{...}: {
  # Power Management Daemon
  services.tlp = {
    enable = true;
    settings = {
      # Values for "always plugged"
      # START_CHARGE_THRESH_BAT0 = 40;
      # STOP_CHARGE_THRESH_BAT0 = 50;
      # Values for "unplugged all the time"
      START_CHARGE_THRESH_BAT0 = 85;
      STOP_CHARGE_THRESH_BAT0 = 90;
      TLP_DEFAULT_MODE = "BAT";
      TLP_PERSISTENT_DEFAULT = 1;
    };
  };
}
