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
  };

  home.packages = with pkgs; [
    xclip                           # Clipboard
    maim                            # Screenshot utility
    arandr                          # GUI fox xrandr
  ];
  programs = {
    feh.enable = true;
  };
}
