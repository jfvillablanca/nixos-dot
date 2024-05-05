{
  inputs,
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.wezterm;
  # WARN: deprecation
  # https://github.com/Misterio77/nix-colors/commit/fc080c51d2a219b40d886870e364243783ed5ca1
  # https://github.com/Misterio77/nix-colors/issues/56
  pathToScheme = builtins.toFile "wezterm-base16.yaml" (inputs.nix-colors.lib.schemeToYAML config.colorScheme);
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
          local colors, _ = wezterm.color.load_base16_scheme("${pathToScheme}")

          return {
            -- ## COLORSCHEME ##
            colors = colors,

            enable_tab_bar = false,

            enable_wayland = false,

            window_close_confirmation = 'NeverPrompt',
          }
        '';
      };
    };
  };
}
