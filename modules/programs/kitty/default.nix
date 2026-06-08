{
  flake.modules.homeManager.kitty = {
    lib,
    pkgs,
    ...
  }: {
    config = {
      programs = {
        kitty = {
          enable = true;
          settings = lib.mkMerge [
            {
              window_padding_width = 5;
              confirm_os_window_close = 0;

              cursor_trail = 1;
              cursor_trail_decay = "0.05 0.2";
              cursor_shape = "block";
              cursor_trail_start_threshold = 0;
              shell_integration = "no-cursor";
            }
            # macOS: send Option as Alt/Meta so tmux M- bindings (pane/window
            # nav) behave exactly as on Linux.
            (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
              macos_option_as_alt = "yes";
            })
          ];
        };
      };
    };
  };
}
