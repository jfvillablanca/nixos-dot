{ pkgs, ... }:
{
  xdg.configFile = {
    "i3-scripts/maim-full.sh" = {
      executable = true;
      text = ''
      #!/bin/sh
      # Set the save directory
      SAVE_DIR=~/Pictures/screenshots
    
      # Check if the save directory exists, create it if it doesn't
      if [ ! -d "$SAVE_DIR" ]; then
        mkdir -p "$SAVE_DIR"
      fi
    
      # Take a screenshot and save it in the save directory with a timestamp as the filename
      maim --hidecursor "$SAVE_DIR/$(date +%Y-%m-%d-%H%M%S).png"
      '';
    };

    "i3-scripts/maim-select" = {
      executable = true;
      text = ''
      #!/bin/sh
      # Set the save directory
      SAVE_DIR=~/Pictures/screenshots
    
      # Check if the save directory exists, create it if it doesn't
      if [ ! -d "$SAVE_DIR" ]; then
        mkdir -p "$SAVE_DIR"
      fi
    
      # Take a screenshot via selection and save it in the save directory with a timestamp as the filename
      maim --noopengl --select "$SAVE_DIR/$(date +%Y-%m-%d-%H%M%S).png"
      '';
    };

    "i3-scripts/maim-select-and-save-to-xclip.sh" = {
      executable = true;
      text = ''
      #!/bin/sh
      # Set the save directory
      SAVE_DIR=~/Pictures/screenshots
    
      # Check if the save directory exists, create it if it doesn't
      if [ ! -d "$SAVE_DIR" ]; then
        mkdir -p "$SAVE_DIR"
      fi
    
      # Take a screenshot and save it to the clipboard
      maim --select | xclip -selection clipboard -t image/png
      '';
    };

    "i3-scripts/i3lock" = {
      executable = true;
      text = ''
      #!/bin/sh

      BLANK='#000000BB'
      OVERLAY='#00000044'
      CLEAR='#ffffff22'
      DEFAULT='#957FB8E6'
      TEXT='#E6C384E6'
      WRONG='#E82424bb'
      VERIFYING='#7AA89FE6'
      
      i3lock \
      --insidever-color=$CLEAR     \
      --ringver-color=$VERIFYING   \
      \
      --insidewrong-color=$CLEAR   \
      --ringwrong-color=$WRONG     \
      \
      --inside-color=$BLANK        \
      --ring-color=$DEFAULT        \
      --line-color=$BLANK          \
      --separator-color=$DEFAULT   \
      \
      --verif-color=$TEXT          \
      --wrong-color=$TEXT          \
      --time-color=$TEXT           \
      --date-color=$TEXT           \
      --layout-color=$TEXT         \
      --keyhl-color=$WRONG         \
      --bshl-color=$WRONG          \
      \
      --screen 1                   \
      --blur 9                     \
      --radius 150                 \
      --ring-width 10              \
      --clock                      \
      --indicator                  \
      --time-str="%H:%M:%S"        \
      '';
    };
  };

  home.packages = with pkgs; [
    xclip                           # Clipboard
    maim                            # Screenshot utility
    arandr                          # GUI fox xrandr
    i3lock-color                    # Lock screen
  ];
  programs = {
    feh.enable = true;
  };
}
