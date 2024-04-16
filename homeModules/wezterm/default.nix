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
            -- ## COLORSCHEME ##
            color_scheme = 'Rosé Pine (Gogh)',

            enable_tab_bar = false,

            enable_wayland = false,

            window_close_confirmation = 'NeverPrompt',
          }
        '';
      };
    };
  };
}
