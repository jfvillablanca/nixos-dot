{
  flake.modules.homeManager.kitty = _: {
    config = {
      programs = {
        kitty = {
          enable = true;
          settings = {
            window_padding_width = 5;
            confirm_os_window_close = 0;

            cursor_trail = 1;
            cursor_trail_decay = "0.05 0.2";
            cursor_shape = "block";
            cursor_trail_start_threshold = 0;
            shell_integration = "no-cursor";
          };
        };
      };
    };
  };
}
