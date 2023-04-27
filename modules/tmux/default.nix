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
      {
        plugin = tmuxPlugins.yank;
        extraConfig = ''
          # Yank-paste
          bind-key -T copy-mode-vi v   send-keys -X begin-selection
          bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
          bind-key -T copy-mode-vi y   send-keys -X copy-selection-and-cancel
        '';
      }
      {
        plugin = tmuxPlugins.tmux-fzf;
        extraConfig = ''
          TMUX_FZF_LAUNCH_KEY="C-f"
          TMUX_FZF_OPTIONS="-p -w 62% -h 38% -m"
          TMUX_FZF_ORDER="session|window|pane|command|keybinding|clipboard|process"
          TMUX_FZF_PANE_FORMAT="[#{window_name}] #{pane_current_command}  [#{pane_width}x#{pane_height}] [history #{history_size}/#{history_limit}, #{history_bytes} bytes] #{?pane_active,[active],[inactive]}"
        '';
      }
      # tmuxPlugins.tilish
    ];
    extraConfig = ''
      # True Color (after a million tries, this is the override that works)
      set -ag terminal-overrides ",$TERM:RGB" 

      # switch panes using Alt-arrow without prefix
      bind -n M-Left  select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up    select-pane -U
      bind -n M-Down  select-pane -D

      # switch windows using Alt-H/L without prefix
      bind -n M-H previous-window
      bind -n M-L next-window

      # Set base index of windows to 1
      set        -g  base-index 1
      set        -g  pane-base-index 1
      set-option -wg pane-base-index 1
      set-option -g  renumber-windows on

      # Open panes in current directory (similar to Zellij) 
      bind '"' split-window -v -c "#{pane_current_path}"
      bind  %  split-window -h -c "#{pane_current_path}"

      # Scratchpad terminal
      bind -n M-/ display-popup -E "tmux new-session -A -s scratch"

      # GitUI popup
      bind -n M-g display-popup -E -h 70% -w 70% "tmux new-session -A -s scratch -c '#{pane_current_path}' 'gitui'"

    '';
    tmuxinator.enable = true;
  };
}
