{ config, pkgs, lib, ... }:
let
  mod = "Mod4";
  term = "alacritty";
in
{
  xsession = {
    windowManager = {
      i3 = {
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
              command = ''
              xrandr \
                  --output eDP-1 --primary \
                      --mode 1920x1080 --pos 0x0    --rotate normal \
                  --output HDMI-1 \
                      --mode 1920x1080 --pos 1920x0 --rotate normal
              '';
              notification = false;
              always = true;
            }
            {
              command = "--no-startup-id picom";
              notification = false;
              always = true;
            }
            {
              command = "--no-startup-id feh --bg-fill ${config.xdg.configHome}/.wallpapers/purplemountain.jpg";
              notification = false;
              always = true;
            }
            {
              command = "--no-startup-id polybar-msg cmd quit; polybar &";
              notification = false;
              always = true;
            }
            {
              command = "--no-startup-id i3-msg 'workspace 1; exec alacritty'";
            }
          ];
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
            # {
            #     position = "top";
            #     statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-top.toml";
            #     fonts = {
            #         names = [ "JetBrainsMono Nerd Font" ];
            #         style = "SemiBold";
            #         size = 13.0;
            #     };
            # }

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
            "${mod}+Shift+Right" = "move right";
            "${mod}+Shift+Down" = "move down";
            "${mod}+Shift+Up" = "move up";
            # "${mod}+Shift+Down" = "move container to output right; focus output right";
            # "${mod}+Shift+Up" = "move container to output left; focus output left";
            # "${mod}+Shift+j" = "move container to workspace next_on_output; workspace next_on_output; focus output current";
            # "${mod}+Shift+k" = "move container to workspace prev_on_output; workspace prev_on_output; focus output current";

            "${mod}+1" = "workspace 1;  workspace 11";
            "${mod}+2" = "workspace 2;  workspace 12";
            "${mod}+3" = "workspace 3;  workspace 13";
            "${mod}+4" = "workspace 4;  workspace 14";
            "${mod}+5" = "workspace 5;  workspace 15";
            "${mod}+6" = "workspace 6;  workspace 16";
            "${mod}+7" = "workspace 7;  workspace 17";
            "${mod}+8" = "workspace 8;  workspace 18";
            "${mod}+9" = "workspace 9;  workspace 19";
            "${mod}+0" = "workspace 10; workspace 20";

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

            "${mod}+semicolon" = "exec ${pkgs.bash}/bin/bash ${config.xdg.configHome}/i3-scripts/maim-full.sh";
            "${mod}+Shift+semicolon" = "exec ${pkgs.bash}/bin/bash ${config.xdg.configHome}/i3-scripts/maim-select-and-save-to-xclip.sh";
            "${mod}+Shift+y" = "exec ${pkgs.bash}/bin/bash ${config.xdg.configHome}/i3-scripts/maim-select";
            "${mod}+Print" = "exec flameshot full";
            "Print" = "exec flameshot gui";
          };
          menu = "exec ${pkgs.rofi}/bin/rofi -show drun";
          fonts = {
            names = [ "JetBrainsMono Nerd Font" ];
            style = "SemiBold";
            size = 11.0;
          };
          defaultWorkspace = "workspace 1";
          workspaceAutoBackAndForth = false;
        };
        extraConfig = ''
        workspace 1  output eDP-1
        workspace 2  output eDP-1
        workspace 3  output eDP-1
        workspace 4  output eDP-1
        workspace 5  output eDP-1
        workspace 6  output eDP-1
        workspace 7  output eDP-1
        workspace 8  output eDP-1
        workspace 9  output eDP-1
        workspace 10 output eDP-1

        workspace 11 output HDMI-1
        workspace 12 output HDMI-1
        workspace 13 output HDMI-1
        workspace 14 output HDMI-1
        workspace 15 output HDMI-1
        workspace 16 output HDMI-1
        workspace 17 output HDMI-1
        workspace 18 output HDMI-1
        workspace 19 output HDMI-1
        workspace 20 output HDMI-1

        mouse_warping none
        '';
      };
    };
  };
}
