{
  flake.modules.homeManager.xdg = {
    lib,
    pkgs,
    config,
    ...
  }: let
    cfg = config.myHomeModules.xdg;
  in {
    options.myHomeModules.xdg = {
      enable =
        lib.mkEnableOption "xdg portals + userDirs"
        // {
          default = true;
        };
    };
    config = lib.mkIf cfg.enable {
      xdg = {
        enable = true;
        portal = {
          enable = true;
          extraPortals = with pkgs; [xdg-desktop-portal-gtk];
          config = {
            common.default = ["gtk"];
            hyprland.default = ["gtk" "hyprland"];
          };
        };
        userDirs = {
          enable = true;
          createDirectories = false;
        };
      };
    };
  };
}
