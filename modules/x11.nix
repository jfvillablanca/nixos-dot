{...}: {
  imports = [
    ./wm/x11
    ./wm/x11/autorandr
    ./wm/x11/polybar
    ./wm/x11/i3status-rust
    ./wm/x11/i3
    ./wm/x11/picom
    ./wm/x11/rofi
  ];

  xsession = {
    enable = true;
    initExtra = "spice-vdagent &"; # starts the x11 spice-vdagent manually especially if running on none+someWM
  };
}
