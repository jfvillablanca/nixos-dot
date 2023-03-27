{ isWayland, ... }:
{
  programs = {
    bash = {
      enable = true;
      enableCompletion = true;
      bashrcExtra =
        if isWayland then ''
          if [ "$(tty)" = "/dev/tty1" ]; then
              exec dbus-run-session sway
          fi
        '' else "";
    };
  };
}
