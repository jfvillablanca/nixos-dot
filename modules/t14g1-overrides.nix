{ config, pkgs, lib, ... }:
{
  imports = [
    ./wm/x11/i3
  ];

  xsession = {
    windowManager.i3 = {
      config.startup = [
        {
          command = "--no-startup-id feh --bg-fill ${config.xdg.configHome}/.wallpapers/kanagawa.jpg";
          notification = false;
          always = true;
        }
      ];
    };
  };
}
