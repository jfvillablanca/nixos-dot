{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.kitty;
in {
  options.myHomeModules.kitty = {
    enable = lib.mkEnableOption "enables kitty";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      kitty = {
        enable = true;
        settings = {
          window_padding_width = 5;

          cursor_trail = 1;
          cursor_trail_decay = "0.05 0.2";
          cursor_shape = "block";
          cursor_trail_start_threshold = 0;
          shell_integration = "no-cursor";
        };
      };
    };
  };
}
