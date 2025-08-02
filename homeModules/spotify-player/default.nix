{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.spotify-player;
in {
  options.myHomeModules.spotify-player = {
    enable =
      lib.mkEnableOption "enables spotify-player"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      spotify-player = {
        enable = true;
        keymaps = [
          {
            command = "None";
            key_sequence = "q";
          }
        ];
      };
    };
  };
}
