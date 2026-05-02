{
  flake.homeModules.wallpapers = {
    lib,
    config,
    ...
  }: let
    cfg = config.myHomeModules.wallpapers;
  in {
    options.myHomeModules.wallpapers = {
      enable =
        lib.mkEnableOption "copy wallpapers into ~/.config/.wallpapers"
        // {
          default = true;
        };
    };
    config = lib.mkIf cfg.enable {
      xdg.configFile.".wallpapers" = {
        source = ./.;
        recursive = true;
      };
    };
  };
}
