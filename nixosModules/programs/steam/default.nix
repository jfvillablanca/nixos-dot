{
  lib,
  config,
  ...
}: let
  cfg = config.myNixosModules.steam;
in {
  options.myNixosModules.steam = {
    enable =
      lib.mkEnableOption "enables steam"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
    };
  };
}
