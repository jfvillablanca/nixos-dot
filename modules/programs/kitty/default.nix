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
              # Disable config live-reload. Value is a debounce in seconds
              # (default 0.1); a negative value disables it. Live-reload is
              # pointless with immutable nix config, and kitty's symlink-aware
              # watcher (kitty #10066) follows the ~/.config/kitty/kitty.conf
              # -> /nix/store symlink and recursively watches a huge tree,
              # exhausting inotify.
              auto_reload_config = -1;

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
