{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.i3;

  mod = "Mod4";
  term = "wezterm";
in {
  options.myHomeModules.i3 = {
    enable =
      lib.mkEnableOption "enables i3"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    xsession = {
      enable = true;
      windowManager = {
        i3 = {
          enable = true;
          config = {
            modifier = mod;
            terminal = term;
            gaps = {
              outer = 0;
              inner = 10;
            };
            startup = [
              {
                command = ''
                  xrandr ${
                    lib.strings.concatStringsSep " " (map (
                        m: let
                          resolution = "--mode ${toString m.width}x${toString m.height} --rate ${toString m.refreshRate}";
                          position = "--pos ${toString m.x}x${toString m.y} --rotate normal";
                        in "--output ${m.name} ${
                          if m.isPrimary
                          then "--primary"
                          else ""
                        } ${
                          if m.enabled
                          then "${resolution} ${position}"
                          else "--off"
                        }"
                      )
                      config.myHomeModules.window-manager.monitors)
                  }
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
                command = "--no-startup-id feh --bg-fill ${config.xdg.configHome}/.wallpapers/desertsunset.jpg";
                notification = false;
                always = true;
              }
              {
                command = "--no-startup-id polybar-msg cmd quit; polybar &";
                notification = false;
                always = true;
              }
              {
                command = "--no-startup-id i3-msg 'workspace 1; exec ${term}'";
              }
            ];
            window = {
              titlebar = false;
              border = 2;
              hideEdgeBorders = "smart";
            };
            floating = {
              border = 7;
              criteria = [];
              modifier = mod;
              titlebar = true;
            };
            bars = [];
            keybindings = let
              generateWorkspaceKeybindings = monitors: let
                numMonitors = builtins.length monitors;
                # for example: on three-monitor config, this assigns the monitor workspaces to a single mod+num and generates:
                #   "${mod}+1" = "workspace 1;  workspace 11;  workspace 21";
                #   "${mod}+2" = "workspace 2;  workspace 12;  workspace 22";
                #    ... and so on
                generateWorkspaceString = workspace: lib.concatStringsSep ";  " (map (n: "workspace ${toString (workspace + n * 10)}") (lib.lists.range 0 (numMonitors - 1)));
                # this one is independent from the number of monitors and is for the `move container to workspace` keybinds:
                #    "${mod}+Shift+1" = "move container to workspace 1";
                #    "${mod}+Shift+2" = "move container to workspace 2";
                #    ... and so on
                generateMoveContainerString = workspace: "move container to workspace ${toString workspace}";
              in
                builtins.listToAttrs (lib.concatMap (i: [
                  {
                    name = "${mod}+${toString i}";
                    value = generateWorkspaceString i;
                  }
                  {
                    name = "${mod}+Shift+${toString i}";
                    value = generateMoveContainerString i;
                  }
                ]) (lib.lists.range 1 5));
            in
              lib.mkOptionDefault (
                generateWorkspaceKeybindings config.myHomeModules.window-manager.monitors
                // {
                  "${mod}+Enter" = "exec ${term}";
                  "${mod}+Shift+q" = "kill";
                  "${mod}+Shift+r" = "restart";
                  "${mod}+Shift+c" = "reload";
                  "${mod}+Shift+e" = "exec i3-nagbar -t warning -m 'Do you want to exit i3?' -b 'Yes' 'i3-msg exit'";
                  "${mod}+Shift+l" = "exec ${pkgs.bash}/bin/bash ${config.xdg.configHome}/i3-scripts/i3lock";

                  "${mod}+Left" = "focus left";
                  "${mod}+Down" = "focus down";
                  "${mod}+Up" = "focus up";
                  "${mod}+Right" = "focus right";

                  "${mod}+Shift+Left" = "move left";
                  "${mod}+Shift+Right" = "move right";
                  "${mod}+Shift+Down" = "move down";
                  "${mod}+Shift+Up" = "move up";
                  "${mod}+Shift+j" = "resize shrink width 10 px";
                  "${mod}+Shift+k" = "resize grow width 10 px";

                  "${mod}+f" = "fullscreen toggle";
                  "${mod}+h" = "split h";
                  "${mod}+v" = "split v";

                  "${mod}+s" = "layout stacking";
                  "${mod}+w" = "layout tabbed";
                  "${mod}+e" = "layout toggle split";

                  "${mod}+Shift+space" = "floating toggle";
                  "${mod}+space" = "focus mode_toggle";

                  "${mod}+Print" = "exec flameshot full";
                  "Print" = "exec flameshot gui";
                }
              );
            menu = "exec ${pkgs.rofi}/bin/rofi -show drun";
            defaultWorkspace = "workspace 1";
            workspaceAutoBackAndForth = false;
          };
          extraConfig = let
            indexOf = elem: list: let
              indexOfRecursive = elem: list: idx:
                if lib.length list == 0
                then -1
                else if lib.head list == elem
                then idx
                else indexOfRecursive elem (lib.tail list) (idx + 1);
            in
              indexOfRecursive elem list 0;

            generateMonitorAssignmentConfig = monitors: let
              monitorNames = map (monitor: monitor.name) monitors;
              generateWorkspaceOutput = monitor: let
                monitorIndex = indexOf monitor monitorNames;
              in
                lib.concatStringsSep "\n" (map (i: "workspace ${toString (i + (monitorIndex * 10))} output ${monitor}") (lib.lists.range 1 5));
            in
              lib.concatStringsSep "\n" (map generateWorkspaceOutput monitorNames);
          in ''
            ${generateMonitorAssignmentConfig config.myHomeModules.window-manager.monitors}
            mouse_warping none
          '';
        };
      };
    };

    xdg.configFile = {
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
      xclip # Clipboard
      i3lock-color # Lock screen
    ];
    programs = {
      feh.enable = true;
    };
  };
}
