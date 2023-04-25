{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    mouse = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    keyMode = "vi";
    escapeTime = 0;
    prefix = "C-a";
    sensibleOnTop = true;
    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
        '';
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
        extraConfig = ''
          # status bar
          set -g status-right '#{prefix_highlight}'
          set -g @prefix_highlight_fg 'white' # default is 'colour231'
          set -g @prefix_highlight_bg 'red'  # default is 'colour04'

          # palette: kanagawa
          set-option -g status-style bg=#2A2A37
          set-option -g status-position top
        '';
      }
      # tmuxPlugins.tilish
    ];
    extraConfig = ''
      # True Color (after a million tries, this is the override that works)
      set -ag terminal-overrides ",$TERM:RGB" 

      # switch panes using Alt-arrow without prefix
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Copy-paste
      bind-key -T copy-mode-vi 'C-v' send -X begin-selection
      bind-key -T copy-mode-vi 'C-y' send -X copy-selection

      # Set base index of windows to 1
      set -g base-index 1
    '';
    tmuxinator.enable = true;
  };
}
