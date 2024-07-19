{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.polybar;
  colors = {
    background = "#AA2A2A37"; # "#2A2A37"
    background-alt = "#BB363646"; # "#363646"
    foreground = "#DCD7BA";
    primary = "#FF9E3B";
    secondary = "#7E9CD8";
    alert = "#C34043";
    disabled = "#727169";
    green = "#76946A";
    magenta = "#957FB8";
    orange = "#FFA066";
    cyan = "#7FB4CA";
  };
in {
  options.myHomeModules.polybar = {
    enable =
      lib.mkEnableOption "enables polybar"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    xdg.configFile."polybar/sound.sh" = {
      source = ./sound.sh;
    };

    services = {
      polybar = {
        enable = true;
        script = "polybar bar &";
        config = {
          "bar/top" = {
            top = true;
            width = "100%";
            height = "24pt";
            radius = 0;
            dpi = 0;
            override-redirect = false;
            inherit (colors) background;
            inherit (colors) foreground;
            line-size = "1pt";
            padding-left = 0;
            padding-right = 3;
            module-margin = 1;
            separator = "|";
            separator-foreground = colors.disabled;
            font-0 = "JetBrainsMono:style=Regular:size=11;2";
            font-1 = "Font Awesome 6 Free:pixelsize=13;2";
            font-2 = "Font Awesome 6 Free Solid:pixelsize=13;2";
            font-3 = "Font Awesome 6 Brands:pixelsize=13;2";
            font-4 = "JetBrainsMono Nerd Font:style=Regular:size=13;2";
            modules-left = "xworkspaces";
            modules-center = "xwindow";
            modules-right = "filesystem network-speed memory cpu battery pipewire date powermenu tray";
            cursor-click = "pointer";
            cursor-scroll = "ns-resize";
            enable-ipc = true;
          };

          "module/tray" = {
            type = "internal/tray";
            tray-size = "50%";
            tray-spacing = "8px";
          };

          "module/xworkspaces" = {
            type = "internal/xworkspaces";
            label-active = "%name%";
            label-active-background = colors.background-alt;
            label-active-underline = colors.primary;
            label-active-padding = 1;
            label-occupied = "%name%";
            label-occupied-padding = 1;
            label-urgent = "%name%";
            label-urgent-background = colors.alert;
            label-urgent-padding = 1;
            label-empty = "%name%";
            label-empty-foreground = colors.disabled;
            label-empty-padding = 1;
          };

          "module/xwindow" = {
            type = "internal/xwindow";
            label = "%title:0:60:...%";
          };

          "module/filesystem" = {
            type = "internal/fs";
            mount-0 = "/";
            interval = 40;
            fixed-values = true;
            warn-percentage = 20;
            format-mounted-prefix = "%{T2}󰨣%{T-} ";
            format-mounted-prefix-foreground = colors.primary;
            format-mounted = "<label-mounted>";
            label-mounted = "%used% used";
          };

          "module/memory" = {
            type = "internal/memory";
            interval = 2;
            format-prefix = "%{T2}%{T-} ";
            format-prefix-foreground = colors.primary;
            label = "%percentage_used:2%%";
          };

          "module/cpu" = {
            type = "internal/cpu";
            interval = 2;
            format-prefix = "%{T2}%{T-} ";
            format-prefix-foreground = colors.primary;
            label = "%percentage:2%%";
          };

          "module/battery" = {
            type = "internal/battery";
            full-at = 98;
            low-at = 10;
            battery = "BAT0";

            format-charging-prefix = "%{T2}%{T-} ";
            format-charging-prefix-foreground = colors.primary;
            format-charging = "<label-charging>";
            label-charging = "%percentage%%";

            format-full-prefix = "%{T2}%{T-} ";
            format-full-prefix-foreground = colors.green;
            format-full = "<label-full>";
            label-full = "%percentage%%";

            ramp-capacity-0 = "";
            ramp-capacity-1 = "";
            ramp-capacity-2 = "";
            ramp-capacity-3 = "";
            ramp-capacity-4 = "";
            ramp-capacity-foreground = colors.primary;
            format-discharging = "<ramp-capacity> <label-discharging>";
            label-discharging = "%percentage%%";

            animation-low-0 = "";
            animation-low-1 = "";
            animation-low-framerate = 200;
            animation-low-0-foreground = colors.primary;
            animation-low-1-foreground = colors.alert;
            format-low = "<animation-low> <label-low>";
            label-low = "%percentage%%";
          };

          "module/network-speed" = {
            type = "internal/network";
            interface-type = "wireless";
            interval = 5;
            format-connected-prefix = "%{T2}󱚶 %{T-} ";
            format-connected-prefix-foreground = colors.primary;
            label-connected = "%downspeed%";
            label-disconnected = "disconnected";
            label-connected-background = colors.background;
          };

          "module/pipewire" = {
            type = "custom/script";
            label = "%output%";
            label-font = 2;
            interval = 2;
            exec = "${config.xdg.configHome}/polybar/sound.sh";
            click-right = "exec pavucontrol &";
            click-left = "${config.xdg.configHome}/polybar/sound.sh mute &";
            scroll-up = "${config.xdg.configHome}/polybar/sound.sh up &";
            scroll-down = "${config.xdg.configHome}/polybar/sound.sh down &";
          };

          # "module/network" = {
          #     type = "internal/network";
          #     # interface =  wlp0s26u1u4
          #     interface-type = "wireless";
          #
          #     interval = 1.0;
          #     accumulate-stats = true;
          #     unknown-as-up = true;
          #
          #     label-connected = "%essid%  󰇚%downspeed:9%";
          #     label-disconnected = "";
          #
          #     format-connected = "<ramp-signal> <label-connected>";
          #     format-disconnected = "<label-disconnected>";
          #
          #     ramp-signal-0 = "";
          #     ramp-signal-1 = "";
          #     ramp-signal-2 = "";
          #     ramp-signal-3 = "";
          #     ramp-signal-4 = "";
          #     ramp-signal-5 = "";
          # };

          "module/date" = {
            type = "internal/date";
            interval = 1;
            date = "%H:%M";
            date-alt = "%Y-%m-%d %H:%M:%S";
            label = "%date%";
            label-foreground = colors.primary;
          };

          "module/powermenu" = {
            type = "custom/menu";
            expand-right = false;
            format-spacing = 1;
            label-open = "";
            label-open-foreground = colors.primary;
            label-close = "󰜺";
            label-close-foreground = colors.secondary;
            label-separator = "|";
            label-separator-foreground = colors.disabled;

            # Powermenu
            menu-0-0 = "Reboot";
            menu-0-0-exec = "menu-open-1";
            menu-0-0-foreground = colors.orange;

            menu-0-1 = "Power Off";
            menu-0-1-exec = "menu-open-2";
            menu-0-1-foreground = colors.orange;

            # Reboot
            menu-1-0 = "Reboot";
            menu-1-0-exec = "systemctl reboot";
            menu-1-0-foreground = colors.alert;
            menu-1-1 = "󰌍";
            menu-1-1-exec = "menu-open-0";
            menu-1-1-foreground = colors.secondary;

            # Shutdown
            menu-2-0 = "Power off";
            menu-2-0-exec = "systemctl poweroff";
            menu-2-0-foreground = colors.alert;
            menu-2-1 = "󰌍";
            menu-2-1-exec = "menu-open-0";
            menu-2-1-foreground = colors.secondary;
          };

          "settings" = {
            screenchange-reload = true;
            pseudo-transparency = false;
          };
        };
      };
    };
  };
}
