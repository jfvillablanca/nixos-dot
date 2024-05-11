{
  inputs,
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.gitui;
  inherit (config.colorScheme) palette;
  inherit (inputs.nix-colors.lib.conversions) hexToRGBString;
in {
  options.myHomeModules.gitui = {
    enable =
      lib.mkEnableOption "enables gitui"
      // {
        default = true;
      };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      gitui = {
        enable = true;
        theme = ''
          (
              selected_tab: Reset,
              command_fg: Rgb(${hexToRGBString "," palette.base05}),
              selection_bg: Rgb(${hexToRGBString "," palette.base02}),
              selection_fg: White,
              cmdbar_bg: Rgb(${hexToRGBString "," palette.base02}),
              cmdbar_extra_lines_bg: Rgb(${hexToRGBString "," palette.base02}),
              disabled_fg: Rgb(${hexToRGBString "," palette.base04}),
              diff_line_add: Green,
              diff_line_delete: Red,
              diff_file_added: LightGreen,
              diff_file_removed: LightRed,
              diff_file_moved: LightMagenta,
              diff_file_modified: Yellow,
              commit_hash: Rgb(${hexToRGBString "," palette.base0F}),
              commit_time: Rgb(${hexToRGBString "," palette.base0D}),
              commit_author: Rgb(${hexToRGBString "," palette.base0E}),
              danger_fg: Red,
              push_gauge_bg: Blue,
              push_gauge_fg: Reset,
              tag_fg: LightMagenta,
              branch_fg: Rgb(${hexToRGBString "," palette.base0A}),
          )
        '';
      };
    };
  };
}
