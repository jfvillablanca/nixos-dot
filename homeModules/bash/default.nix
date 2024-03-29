{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.bash;
in {
  options.myHomeModules.bash = {
    enable =
      lib.mkEnableOption "enables bash"
      // {
        default = true;
      };
    isWayland =
      lib.mkEnableOption "flag if using Wayland as display server"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      bash = {
        enable = true;
        enableCompletion = true;
        bashrcExtra =
          if cfg.isWayland
          then ''
            if [ "$(tty)" = "/dev/tty1" ]; then
                exec dbus-run-session sway
            fi
          ''
          else "";
      };
    };
  };
}
