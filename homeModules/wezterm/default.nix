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
        extraConfig = ''
          return {
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
