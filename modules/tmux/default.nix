{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    mouse = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    keyMode = "vi";
    prefix = "C-a";
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
            set -g status-right '#{prefix_highlight} | %a %Y-%m-%d %H:%M'
      # palette: kanagawa
      set-option -g status-style bg=#2A2A37
      set-option -g status-position top
      # True Color (after a million tries, this is the override that works)
      set -ag terminal-overrides ",$TERM:RGB" 

      # switch panes using Alt-arrow without prefix
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D
    '';
    tmuxinator.enable = true;
  };
}
