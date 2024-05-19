{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.waybar;
  inherit (config.colorScheme) palette;
in {
  options.myHomeModules.waybar = {
    enable =
      lib.mkEnableOption "enables waybar"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      waybar = {
        enable = true;
        settings = {
          main = {
            # General Settings

            # Position TOP
            "layer" = "top";
            "margin-left" = 0;
            "margin-right" = 0;
            "margin-bottom" = 0;
            "spacing" = 0;

            # Modules Left
            "modules-left" = [
              "custom/nixos"
              "memory"
              "cpu"
              "disk"
            ];

            # Modules Center
            "modules-center" = [
              "hyprland/workspaces"
            ];

            # Modules Right
            "modules-right" = [
              "privacy"
              "battery"
              "group/group-audio"
              "network"
              "tray"
              "clock"
              "custom/swaync"
            ];

            ###############################
            ########### MODULES ###########
            ###############################

            "custom/nixos" = {
              "format" = " ";
              "on-click" = "${lib.getExe pkgs.wofi} --show drun";
              "tooltip" = false;
            };

            # Memory
            "memory" = {
              "interval" = 1;
              "format" = "󰍛 {percentage}%";
              "states" = {
                "warning" = 80;
                "critical" = 90;
              };
            };

            # CPU
            "cpu" = {
              "interval" = 1;
              "format" = "󰻠 {usage}%";
              "states" = {
                "warning" = 80;
                "critical" = 90;
              };
            };
            # Disk
            "disk" = {
              "interval" = 30;
              "format" = "󰨣 {used}";
              "path" = "/";
              "on-click" = "${lib.getExe pkgs.wezterm} -e btop";
            };

            # Workspaces
            "hyprland/workspaces" = {
              "on-click" = "activate";
              "active-only" = false;
              "all-outputs" = true;
              "format" = "{}";
              "format-icons" = {
                "urgent" = "";
                "active" = "";
                "default" = "";
              };
              "persistent-workspaces" = {
                "*" = 5;
              };
            };

            # Privacy
            "privacy" = {
              "icon-spacing" = 0;
              "icon-size" = 14;
              "transition-duration" = 250;
              "modules" = [
                {
                  "type" = "screenshare";
                  "tooltip" = true;
                  "tooltip-icon-size" = 20;
                }
                {
                  "type" = "audio-in";
                  "tooltip" = true;
                  "tooltip-icon-size" = 20;
                }
              ];
            };

            # Battery
            "battery" = {
              "interval" = 10;
              "states" = {
                "warning" = 20;
                "critical" = 10;
              };
              "format" = "{icon} {capacity}%";
              "format-icons" = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
              "format-full" = "{icon} {capacity}%";
              "format-charging" = "󰂄 {capacity}%";
              "tooltip" = false;
            };

            # Pulseaudio
            "group/group-audio" = {
              "orientation" = "horizontal";
              "drawer" = {
                "transition-duration" = 500;
                "children-class" = "";
                "transition-left-to-right" = false;
              };
              "modules" = [
                "pulseaudio"
                "pulseaudio/slider"
              ];
            };

            "pulseaudio" = {
              "scroll-step" = 2;
              "format" = "{icon} {volume}%";
              "format-muted" = "󰝟";
              "format-source" = "";
              "format-source-muted" = "";
              "format-icons" = {
                "speaker" = "󰕾";
                "hdmi" = "󰓃";
                "headphone" = "󰋋";
                "hands-free" = "?";
                "headset" = "󰋎";
                "phone" = "";
                "portable" = "";
                "car" = "";
                "default" = "󰕾";
              };
              "on-click-right" = "hyprctl dispatch exec [floating] ${lib.getExe pkgs.pavucontrol}";
              "on-scroll-up" = "wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+";
              "on-scroll-down" = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
              "on-click" = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            };

            "pulseaudio/slider" = {
              "orientation" = "horizontal";
            };

            # Network
            "network" = {
              "format" = "{icon}  {signalStrength}%";
              "format-icons" = ["󰤟" "󰤢" "󰤥" "󰤨"];
              "format-ethernet" = "  {ipaddr}";
              "format-disconnected" = "󰤭";
              "tooltip-format" = " {ifname} via {gwaddri}";
              "tooltip-format-wifi" = "󰤨  {essid} ({signalStrength}%)";
              "tooltip-format-ethernet" = "  {ifname} ({ipaddr}/{cidr})";
              "tooltip-format-disconnected" = "Disconnected";
              "max-length" = 50;
              "on-click" = "hyprctl dispatch exec [floating] ${lib.getExe pkgs.wezterm} -- -e nmtui connect";
            };

            # System tray
            "tray" = {
              "spacing" = 10;
            };

            # Clock
            "clock" = {
              "interval" = 1;
              "format" = "{:%I:%M %p  %A %b %d}";
              "tooltip" = true;
              "tooltip-format" = "{=%A; %d %B %Y}\n<tt>{calendar}</tt>";
            };

            # SwayNC
            "custom/swaync" = {
              tooltip = false;
              format = "{icon}";
              format-icons = let
                notif = "#${palette.base08}"; # red
              in {
                notification = "<span foreground='${notif}'><sup></sup></span>";
                none = "";
                dnd-notification = "<span foreground='${notif}'><sup></sup></span>";
                dnd-none = "";
                inhibited-notification = "<span foreground='${notif}'><sup></sup></span>";
                inhibited-none = "";
                dnd-inhibited-notification = "<span foreground='${notif}'><sup></sup></span>";
                dnd-inhibited-none = "";
              };
              return-type = "json";
              exec-if = "which swaync-client";
              exec = "swaync-client -swb";
              on-click = "swaync-client -t -sw";
              on-click-right = "swaync-client -d -sw";
              escape = true;
            };
          };
        };

        style = let
          font = "JetBrainsMono";
          borderRadiusWaybar = "15px";
          borderRadiusTooltip = "10px";
          my = "2px";
          mx = "5px";
          pt = "2px";
          pb = "0px";
          pl = "8px";
          pr = "8px";
          text-lg = "24px";
          text-sm = "14px";

          backgroundlight = "#${palette.base04}";
          backgrounddark = "#${palette.base00}";
          workspacesbackground = "#${palette.base03}";
          textcolordark = "#${palette.base00}";
          textcolor1 = "#${palette.base05}";
          textcolor2 = "#${palette.base06}";
          textcolor3 = "#${palette.base07}";
          iconcolor = "#${palette.base0D}";

          chargingcolor = "#${palette.base0C}"; # cyan
          warningcolor = "#${palette.base0A}"; # yellow
          errorcolor = "#${palette.base08}"; # red
          sliderhighlight = "#${palette.base0B}"; # green
          slidertrough = "#${palette.base0E}"; # purple
        in ''
          /* -----------------------------------------------------
           * General
           * ----------------------------------------------------- */

          * {
              font-family: ${font};
              border: none;
              border-radius: 0px;
          }

          window#waybar {
            background: transparent;
          }

          /* -----------------------------------------------------
           * Modules
           * ----------------------------------------------------- */

          .modules-left > widget:first-child > #workspaces {
              margin-left: 0;
          }

          .modules-right > widget:last-child > #workspaces {
              margin-right: 0;
          }

          /* -----------------------------------------------------
           * Custom Modules
           * ----------------------------------------------------- */

          #custom-nixos {
              background-color: ${backgrounddark};
              font-size: ${text-lg};
              color: ${iconcolor};
              border-radius: ${borderRadiusWaybar};
              padding-left: 10px;
              padding-right: 5px;
              margin: ${my} ${mx};
          }

          /* -----------------------------------------------------
           * Memory, CPU, Disk
           * ----------------------------------------------------- */

          #memory, #cpu, #disk {
              background-color: ${backgrounddark};
              font-size: ${text-sm};
              color: ${textcolor2};
              border-radius: ${borderRadiusWaybar};
              padding: ${pt} ${pr} ${pb} ${pl};
              margin: ${my} ${mx};
          }

          #memory.warning, #cpu.warning {
              color: ${warningcolor};
          }

          #memory.critical, #cpu.critical {
              color: ${errorcolor};
          }

          /* -----------------------------------------------------
           * Workspaces
           * ----------------------------------------------------- */

          #workspaces {
              margin: 5px 1px 5px 1px;
              padding: 0;
              border-radius: ${borderRadiusWaybar};
              border: 0px;
              font-weight: bold;
              font-style: normal;
              font-size: ${text-sm};
              color: ${textcolor1};
          }

          #workspaces button {
              padding: 0px 5px;
              margin: 4px 3px;
              border-radius: ${borderRadiusWaybar};
              border: 0px;
              color: ${textcolor3};
              transition: all 0.3s ease-in-out;
          }

          #workspaces button.active {
              color: ${textcolor1};
              background: ${workspacesbackground};
              border-radius: ${borderRadiusWaybar};
              min-width: 40px;
              transition: all 0.3s ease-in-out;
          }

          #workspaces button:hover {
              color: ${textcolor1};
              background: ${workspacesbackground};
              border-radius: ${borderRadiusWaybar};
          }


          /* -----------------------------------------------------
           * Privacy
           * ----------------------------------------------------- */

          #privacy {
              background-color: ${backgrounddark};
              font-size: ${text-sm};
              color: ${textcolor2};
              border-radius: ${borderRadiusWaybar};
              /*
                NOTE: workaround to remove module if nothing is recording
                https://github.com/Alexays/Waybar/issues/2974
              */
              padding: 0px;
          }

          #privacy-item.screenshare,
          #privacy-item.audio-in {
              padding: ${pt} ${pr} ${pb} ${pl};
              margin: ${my} ${mx};
          }

          #privacy-item.screenshare {
              color: ${errorcolor};
          }

          /* -----------------------------------------------------
           * Battery
           * ----------------------------------------------------- */

          #battery {
              background-color: ${backgrounddark};
              font-size: ${text-sm};
              color: ${textcolor2};
              border-radius: ${borderRadiusWaybar};
              padding: ${pt} ${pr} ${pb} ${pl};
              margin: ${my} ${mx};
          }

          #battery.charging, #battery.plugged {
            color: ${chargingcolor};
          }

          @keyframes blink-warning {
              to {
                  background-color: ${warningcolor};
                  color: ${textcolordark};
              }
          }

          #battery.warning:not(.charging) {
              background-color: ${textcolordark};
              color: ${warningcolor};
              animation-name: blink-warning;
              animation-duration: 1.0s;
              animation-timing-function: linear;
              animation-iteration-count: infinite;
              animation-direction: alternate;
          }

          @keyframes blink-critical {
              to {
                  background-color: ${errorcolor};
                  color: ${textcolor3};
              }
          }

          #battery.critical:not(.charging) {
              background-color: ${textcolor3};
              color: ${errorcolor};
              animation-name: blink-critical;
              animation-duration: 0.3s;
              animation-timing-function: linear;
              animation-iteration-count: infinite;
              animation-direction: alternate;
          }

          /* -----------------------------------------------------
           * Pulseaudio
           * ----------------------------------------------------- */

          #group-audio {
              background-color: ${backgrounddark};
              font-size: ${text-sm};
              color: ${textcolor2};
              border-radius: ${borderRadiusWaybar};
              padding: ${pt} ${pr} ${pb} ${pl};
              margin: ${my} ${mx};
          }

          #pulseaudio.muted {
              background-color: ${backgrounddark};
              color: ${textcolor1};
          }

          slider {
              min-height: 0px;
              min-width: 0px;
              opacity: 0;
              background-image: none;
              border: none;
              box-shadow: none;
          }

          trough {
              min-height: 10px;
              min-width: 80px;
              border-radius: 5px;
              background-color: ${slidertrough};
          }

          highlight {
              min-width: 10px;
              border-radius: 5px;
          }

          #pulseaudio-slider highlight {
              background-color: ${sliderhighlight};
          }

          /* -----------------------------------------------------
           * Network
           * ----------------------------------------------------- */

          #network {
              background-color: ${backgrounddark};
              font-size: ${text-sm};
              color: ${textcolor2};
              border-radius: ${borderRadiusWaybar};
              padding: ${pt} ${pr} ${pb} ${pl};
              margin: ${my} ${mx};
          }

          #network.ethernet {
              background-color: ${backgrounddark};
              color: ${textcolor2};
          }

          #network.wifi {
              background-color: ${backgrounddark};
              color: ${textcolor2};
          }

          /* -----------------------------------------------------
           * Tray
           * ----------------------------------------------------- */

          #tray {
              margin: 0 10px;
          }

          #tray > .passive {
              -gtk-icon-effect: dim;
          }

          #tray > .needs-attention {
              -gtk-icon-effect: highlight;
              background-color: ${errorcolor};
          }

          /* -----------------------------------------------------
           * Clock
           * ----------------------------------------------------- */

          #clock {
              background-color: ${backgrounddark};
              font-size: ${text-sm};
              color: ${textcolor1};
              border-radius: ${borderRadiusWaybar};
              padding: ${pt} ${pr} ${pb} ${pl};
              margin: ${my} ${mx};
          }

          /* -----------------------------------------------------
           * SwayNC
           * ----------------------------------------------------- */

          #custom-swaync {
              background-color: ${backgrounddark};
              font-size: ${text-sm};
              color: ${textcolor1};
              border-radius: ${borderRadiusWaybar};
              padding: ${pt} ${pr} ${pb} ${pl};
              margin: ${my} ${mx};
          }

          /* -----------------------------------------------------
           * Tooltips
           * ----------------------------------------------------- */

          tooltip {
              border-radius: ${borderRadiusTooltip};
              background-color: ${backgroundlight};
              opacity:0.8;
              padding:20px;
              margin:0px;
          }

          tooltip label {
              color: ${textcolordark};
          }
        '';
      };
    };
  };
}
