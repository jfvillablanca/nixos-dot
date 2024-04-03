{
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
    })
    (lib.mkIf (cfg.enable && cfg.wm == "hyprland") {
      myHomeModules = {
        hyprland.enable = true;
      };
    })
  ];
}
