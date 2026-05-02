{
  flake.modules.homeManager.bash = {
    lib,
    config,
    ...
  }: {
    options.myHomeModules.bash = {
      isWayland =
        lib.mkEnableOption "flag if using Wayland as display server"
        // {
          default = false;
        };
    };
    config = {
      programs = {
        bash = {
          enable = true;
          enableCompletion = true;
          bashrcExtra =
            if config.myHomeModules.bash.isWayland
            then ''
              if [ "$(tty)" = "/dev/tty1" ]; then
                  exec dbus-run-session sway
              fi
            ''
            else "";
        };
      };
    };
  };
}
