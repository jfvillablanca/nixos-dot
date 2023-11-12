{ pkgs, ... }:
{
  programs = {
    wezterm = {
      enable = true;
      extraConfig = ''
        return {
          -- ## COLORSCHEME ##

          color_scheme = 'rose-pine-moon',

          -- ## OPTIONS ##

          enable_tab_bar = false,
        }
      '';
    };
  };
}
