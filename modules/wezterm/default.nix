{ ... }:
{
  programs = {
    wezterm = {
      enable = true;
      extraConfig = ''
        return {
          -- ## COLORSCHEME ##

          color_scheme = 'Rosé Pine (Gogh)',
          -- color_scheme = 'Dracula',
          -- color_scheme = 'Catppuccin Macchiato',

          -- ## FONT ##
          -- font = wezterm.font_with_fallback({
          --        "FiraCode Nerd Font",
          --        "JetBrains Mono"
          --  }),

          -- ## OPTIONS ##

          enable_tab_bar = false,
        }
      '';
    };
  };
}
