{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.wezterm;
in {
  options.myHomeModules.wezterm = {
    enable =
      lib.mkEnableOption "enables wezterm"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      wezterm = {
        enable = true;
        extraConfig =
          /*
          lua
          */
          ''
            return {
              -- NOTE: workaround due to text rendering as color blocks
              -- https://github.com/wez/wezterm/issues/5990
              front_end = "WebGpu",

              enable_tab_bar = false,

              enable_wayland = false,

              window_close_confirmation = 'NeverPrompt',

              warn_about_missing_glyphs = false,
            }
          '';
      };
    };
  };
}
