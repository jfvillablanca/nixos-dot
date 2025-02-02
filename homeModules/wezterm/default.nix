{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.wezterm;
in {
  options.myHomeModules.wezterm = {
    enable = lib.mkEnableOption "enables wezterm";

    frontEnd = lib.mkOption {
      type = lib.types.enum ["WebGpu" "OpenGL"];
      default = "WebGpu";
      description = "Select the front end for wezterm. Options are 'WebGpu' or 'OpenGL'.";
      example = "OpenGL";
    };

    enableWayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable Wayland support in wezterm.";
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
              -- front_end = "WebGpu",
              front_end = "${cfg.frontEnd}",

              enable_tab_bar = false,

              enable_wayland = true,

              window_close_confirmation = 'NeverPrompt',

              warn_about_missing_glyphs = false,
            }
          '';
      };
    };
  };
}
