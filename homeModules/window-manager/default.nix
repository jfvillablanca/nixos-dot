{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.window-manager;

  wmType = lib.types.enum [
    "i3"
    "hyprland"
  ];
in {
  options.myHomeModules.window-manager = {
    enable =
      lib.mkEnableOption "enables window-manager"
      // {
        default = true;
      };
    wm = lib.mkOption {
      type = wmType;
      default = "i3";
    };
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
        };
      });
    };
  };
  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.wm == "i3") {
      myHomeModules = {
        i3.enable = true;
        autorandr.enable = true;
        picom.enable = true;
        polybar.enable = true;
        rofi.enable = true;
      };

      home.packages = with pkgs; [
        simplescreenrecorder
      ];
    })
    (lib.mkIf (cfg.enable && cfg.wm == "hyprland") {
      myHomeModules = {
        hyprland.enable = true;
        wofi.enable = true;
        walker.enable = true;
        eww.enable = true;
        waybar.enable = true;
      };

      home.packages = with pkgs; [
        wl-clipboard
      ];
    })
  ];
}
