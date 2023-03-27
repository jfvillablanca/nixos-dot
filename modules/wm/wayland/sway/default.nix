{ config, pkgs, lib, ... }:
let
  mod = "Mod4";
  term = "alacritty";
in
{
  wayland = {
    windowManager.sway = {
      enable = true;
      config = {
        modifier = mod;
        terminal = term;

        gaps = {
          outer = 0;
          inner = 5;
        };
        startup = [
          {
            command = "alacritty";
          }
        ];

        output = {
          Virtual-1 = {
            mode = "1920x1080";
            bg = "${config.xdg.configHome}/.wallpapers/firewatch.jpg fill";
          };
        };

        window = {
          titlebar = false;
          border = 2;
          hideEdgeBorders = "smart";
        };
        floating = {
          border = 7;
          criteria = [ ];
          modifier = mod;
          titlebar = true;
        };
        bars = [

        ];
        keybindings = lib.mkOptionDefault {
          "${mod}+t" = "exec ${term}";
          "${mod}+q" = "kill";
          "${mod}+Shift+r" = "restart";
          "${mod}+Shift+c" = "reload";
          "${mod}+Shift+e" =
            "exec i3-nagbar -t warning -m 'Do you want to exit i3?' -b 'Yes' 'i3-msg exit'";

          "${mod}+Left" = "focus left";
          "${mod}+Down" = "focus down";
          "${mod}+Up" = "focus up";
          "${mod}+Right" = "focus right";

          "${mod}+Shift+Left" = "move left";
          "${mod}+Shift+Down" = "move down";
          "${mod}+Shift+Up" = "move up";
          "${mod}+Shift+Right" = "move right";

          "${mod}+1" = "workspace 1";
          "${mod}+2" = "workspace 2";
          "${mod}+3" = "workspace 3";
          "${mod}+4" = "workspace 4";
          "${mod}+5" = "workspace 5";
          "${mod}+6" = "workspace 6";
          "${mod}+7" = "workspace 7";
          "${mod}+8" = "workspace 8";
          "${mod}+9" = "workspace 9";
          "${mod}+0" = "workspace 10";

          "${mod}+Shift+1" = "move container to workspace 1";
          "${mod}+Shift+2" = "move container to workspace 2";
          "${mod}+Shift+3" = "move container to workspace 3";
          "${mod}+Shift+4" = "move container to workspace 4";
          "${mod}+Shift+5" = "move container to workspace 5";
          "${mod}+Shift+6" = "move container to workspace 6";
          "${mod}+Shift+7" = "move container to workspace 7";
          "${mod}+Shift+8" = "move container to workspace 8";
          "${mod}+Shift+9" = "move container to workspace 9";
          "${mod}+Shift+0" = "move container to workspace 10";

          "${mod}+f" = "fullscreen toggle";
          "${mod}+h" = "split h";
          "${mod}+v" = "split v";

          "${mod}+s" = "layout stacking";
          "${mod}+w" = "layout tabbed";
          "${mod}+e" = "layout toggle split";

          "${mod}+Shift+space" = "floating toggle";
          "${mod}+space" = "focus mode_toggle";
        };
        # menu = "";
        fonts = {
          names = [ "JetBrainsMono Nerd Font" ];
          style = "SemiBold";
          size = 11.0;
        };
        defaultWorkspace = "workspace 1";
        workspaceAutoBackAndForth = true;
      };
    };
  };
}
