# Data-only feature: declares the per-host monitor layout that desktop
# components (i3, hyprland, autorandr, polybar) read via
# `config.myHomeModules.window-manager.{monitors,statusBarMonitor}`.
#
# Picking a window manager is now done by importing one of the
# `i3-stack` or `hyprland-stack` meta-features rather than toggling a
# `wm` enum here.
{
  flake.modules.homeManager.window-manager = {lib, ...}: {
    options.myHomeModules.window-manager = {
      monitors = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              example = "DP-1";
            };
            isPrimary = lib.mkOption {
              type = lib.types.bool;
              description = "this option only works for window managers using xrandr";
              default = false;
            };
            width = lib.mkOption {
              type = lib.types.int;
              example = 1920;
            };
            height = lib.mkOption {
              type = lib.types.int;
              example = 1080;
            };
            refreshRate = lib.mkOption {
              type = lib.types.int;
              default = 60;
            };
            x = lib.mkOption {
              type = lib.types.int;
              default = 0;
            };
            y = lib.mkOption {
              type = lib.types.int;
              default = 0;
            };
            enabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
            rotate = lib.mkOption {
              type = lib.types.str;
              default = "normal";
            };
            fingerprint = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                EDID hex from `autorandr --fingerprint`. When set for
                every monitor in the list, the autorandr feature
                synthesises a declarative profile keyed off these
                fingerprints, so the layout reapplies on udev hotplug
                events instead of relying on a one-shot session-start
                xrandr command. Stable across reboots; tied to the
                physical monitor.
              '';
            };
          };
        });
        default = [];
      };
      statusBarMonitor = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "which monitor to place the status bar on (read by polybar)";
      };
    };
  };
}
