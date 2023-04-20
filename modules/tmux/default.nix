{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    mouse = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    keyMode = "vi";
    newSession = true;
    sensibleOnTop = true;
    historyLimit = 5000;
    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = "set -g @resurrect-strategy-nvim 'session'";
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '60' # minutes
        '';
      }
      {
        plugin = tmuxPlugins.prefix-highlight;
        extraConfig = "";
      }
      # tmuxPlugins.tilish
    ];
    extraConfig = ''
      set-option -ga terminal-overrides ",tmux-256color:Tc"
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'  # undercurl support
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # underscore colours - needs tmux-3.0
      set -as terminal-overrides ',xterm*:Tc:sitm=\E[3m'

            set -g status-right '#{prefix_highlight} | %a %Y-%m-%d %H:%M'

      # palette: kanagawa
      set-option -g status-style bg=#2A2A37
      set-option -g status-position top


      # switch panes using Alt-arrow without prefix
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D
    '';
    tmuxinator.enable = true;
  };
}
