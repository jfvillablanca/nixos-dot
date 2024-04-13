{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.waybar;
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
            ];

            # Modules Center
            "modules-center" = [
              "hyprland/workspaces"
            ];

            # Modules Right
            "modules-right" = [
              "pulseaudio"
              "network"
              "group/hardware"
              "tray"
              "custom/exit"
              "clock"
            ];

            ###############################
            ########### MODULES ###########
            ###############################

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

            # System tray
            "tray" = {
              "spacing" = 10;
            };

            # Clock
            "clock" = {
              "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
              "format-alt" = "{:%Y-%m-%d}";
            };

            # CPU
            "cpu" = {
              "format" = "/ C {usage}% ";
              "on-click" = "${lib.getExe pkgs.wezterm} -e btop";
            };

            # Memory
            "memory" = {
              "format" = "/ M {}% ";
              "on-click" = "${lib.getExe pkgs.wezterm} -e btop";
            };

            # Harddisc space used
            "disk" = {
              "interval" = 30;
              "format" = "D {percentage_used}% ";
              "path" = "/";
              "on-click" = "${lib.getExe pkgs.wezterm} -e btop";
            };

            # Group Hardware
            "group/hardware" = {
              "orientation" = "inherit";
              "drawer" = {
                "transition-duration" = 300;
                "children-class" = "not-memory";
                "transition-left-to-right" = false;
              };
              "modules" = [
                "disk"
                "cpu"
                "memory"
              ];
            };

            # Network
            "network" = {
              "format" = "{ifname}";
              "format-wifi" = "   {signalStrength}%";
              "format-ethernet" = "  {ipaddr}";
              "format-disconnected" = "Not connected"; #An empty format will hide the module.
              "tooltip-format" = " {ifname} via {gwaddri}";
              "tooltip-format-wifi" = "   {essid} ({signalStrength}%)";
              "tooltip-format-ethernet" = "  {ifname} ({ipaddr}/{cidr})";
              "tooltip-format-disconnected" = "Disconnected";
              "max-length" = 50;
              "on-click" = "hyprctl dispatch exec [floating] ${lib.getExe pkgs.wezterm} -- -e nmtui connect";
            };

            # Pulseaudio
            "pulseaudio" = {
              # "scroll-step"= 1; // %, can be a float
              "format" = "{icon} {volume}%";
              "format-bluetooth" = "{volume}% {icon} {format_source}";
              "format-bluetooth-muted" = " {icon} {format_source}";
              "format-muted" = " {format_source}";
              "format-source" = "{volume}% ";
              "format-source-muted" = "";
              "format-icons" = {
                "headphone" = "";
                "hands-free" = "";
                "headset" = "";
                "phone" = "";
                "portable" = "";
                "car" = "";
                "default" = ["" " " " "];
              };
              "on-click" = "hyprctl dispatch exec [floating] ${lib.getExe pkgs.pavucontrol}";
            };

            # Other
            "user" = {
              "format" = "{user}";
              "interval" = 60;
              "icon" = false;
            };
          };
        };

        # TODO: Rework the CSS here lmao
        style = ''
          @define-color backgroundlight #${config.colorScheme.palette.base06};
          @define-color backgrounddark #${config.colorScheme.palette.base06};
          @define-color workspacesbackground1 #${config.colorScheme.palette.base06};
          @define-color workspacesbackground2 #${config.colorScheme.palette.base03};
          @define-color bordercolor #${config.colorScheme.palette.base06};
          @define-color textcolor1 #${config.colorScheme.palette.base00};
          @define-color textcolor2 #${config.colorScheme.palette.base00};
          @define-color textcolor3 #${config.colorScheme.palette.base06};
          @define-color iconcolor #${config.colorScheme.palette.base06};

          /* -----------------------------------------------------
           * General
           * ----------------------------------------------------- */

          * {
              font-family: "Fira Sans Semibold", FontAwesome, Roboto, Helvetica, Arial, sans-serif;
              border: none;
              border-radius: 0px;
          }

          window#waybar {
              background-color: rgba(0,0,0,0.2);
              border-bottom: 0px solid #ffffff;
              /* color: #FFFFFF; */
              transition-property: background-color;
              transition-duration: .5s;
          }

          /* -----------------------------------------------------
           * Workspaces
           * ----------------------------------------------------- */

          #workspaces {
              margin: 5px 1px 6px 1px;
              padding: 0px 1px;
              border-radius: 15px;
              border: 0px;
              font-weight: bold;
              font-style: normal;
              font-size: 16px;
              color: @textcolor1;
          }

          #workspaces button {
              padding: 0px 5px;
              margin: 4px 3px;
              border-radius: 15px;
              border: 0px;
              color: @textcolor3;
              transition: all 0.3s ease-in-out;
          }

          #workspaces button.active {
              color: @textcolor1;
              background: @workspacesbackground2;
              border-radius: 15px;
              min-width: 40px;
              transition: all 0.3s ease-in-out;
          }

          #workspaces button:hover {
              color: @textcolor1;
              background: @workspacesbackground2;
              border-radius: 15px;
          }

          /* -----------------------------------------------------
           * Tooltips
           * ----------------------------------------------------- */

          tooltip {
              border-radius: 10px;
              background-color: @backgroundlight;
              opacity:0.8;
              padding:20px;
              margin:0px;
          }

          tooltip label {
              color: @textcolor2;
          }

          /* -----------------------------------------------------
           * Window
           * ----------------------------------------------------- */

          #window {
              background: @backgroundlight;
              margin: 10px 15px 10px 0px;
              padding: 2px 10px 0px 10px;
              border-radius: 12px;
              color:@textcolor2;
              font-size:16px;
              font-weight:normal;
          }

          window#waybar.empty #window {
              background-color:transparent;
          }

          /* -----------------------------------------------------
           * Taskbar
           * ----------------------------------------------------- */

          #taskbar {
              background: @backgroundlight;
              margin: 6px 15px 6px 0px;
              padding:0px;
              border-radius: 15px;
              font-weight: normal;
              font-style: normal;
              border: 3px solid @backgroundlight;
          }

          #taskbar button {
              margin:0;
              border-radius: 15px;
              padding: 0px 5px 0px 5px;
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

          #custom-appmenu {
              background-color: @backgrounddark;
              font-size: 16px;
              color: @textcolor1;
              border-radius: 15px;
              padding: 2px 10px 0px 10px;
              margin: 10px 15px 10px 10px;
          }

          /* -----------------------------------------------------
           * Hardware Group
           * ----------------------------------------------------- */

           #disk,#memory,#cpu {
              margin:0px;
              padding:0px;
              font-size:16px;
              color:@iconcolor;
          }

          /* -----------------------------------------------------
           * Clock
           * ----------------------------------------------------- */

          #clock {
              background-color: @backgrounddark;
              font-size: 16px;
              color: @textcolor1;
              border-radius: 15px;
              padding: 2px 10px 0px 10px;
              margin: 10px 15px 10px 0px;
          }

          /* -----------------------------------------------------
           * Pulseaudio
           * ----------------------------------------------------- */

          #pulseaudio {
              background-color: @backgroundlight;
              font-size: 16px;
              color: @textcolor2;
              border-radius: 15px;
              padding: 2px 10px 0px 10px;
              margin: 10px 15px 10px 0px;
          }

          #pulseaudio.muted {
              background-color: @backgrounddark;
              color: @textcolor1;
          }

          /* -----------------------------------------------------
           * Network
           * ----------------------------------------------------- */

          #network {
              background-color: @backgroundlight;
              font-size: 16px;
              color: @textcolor2;
              border-radius: 15px;
              padding: 2px 10px 0px 10px;
              margin: 10px 15px 10px 0px;
          }

          #network.ethernet {
              background-color: @backgroundlight;
              color: @textcolor2;
          }

          #network.wifi {
              background-color: @backgroundlight;
              color: @textcolor2;
          }

          /* -----------------------------------------------------
           * Tray
           * ----------------------------------------------------- */

          #tray {
              background-color: #2980b9;
          }

          #tray > .passive {
              -gtk-icon-effect: dim;
          }

          #tray > .needs-attention {
              -gtk-icon-effect: highlight;
              background-color: #eb4d4b;
          }

          /* -----------------------------------------------------
           * Other
           * ----------------------------------------------------- */

          label:focus {
              background-color: #000000;
          }

          #backlight {
              background-color: #90b1b1;
          }

          #network {
              background-color: #2980b9;
          }

          #network.disconnected {
              background-color: #f53c3c;
          }
        '';
      };
    };
  };
}
