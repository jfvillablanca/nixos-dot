{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.nixosModules.steam;
in {
  options.nixosModules.steam = {
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
