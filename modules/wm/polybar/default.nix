{ ... }:
let
    colors = {
        background = "#AA2A2A37";        # "#2A2A37"
        background-alt = "#BB363646";      # "#363646" 
        foreground = "#DCD7BA";
        primary = "#FF9E3B";
        secondary = "#7E9CD8";
        alert = "#C34043";
        disabled = "#727169";

        green = "#76946A"; #
        magenta = "#957FB8";
        orange = "#FFA066";
        cyan = "#7FB4CA";
        black = "#2A2A37";
        white = "#DCD7BA";
    };
in
{
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
                    background = colors.background;
                    foreground = colors.foreground;

                    line-size = "1pt";

                    # border-size = "4pt";
                    # border-color = "#00000000";

                    padding-left = 0;
                    padding-right = 3;

                    module-margin = 1;

                    separator = "|";
                    separator-foreground = colors.disabled;

                    font-0 = "JetBrainsMono Nerd Font:style=Regular:size=11;2";
                    font-1 = "Font Awesome 6 Free-Solid:style=Regular:size=11;2";
                    font-2 = "Font Awesome 6 Free-Brands:style=Regular:size=11;2";
                    font-3 = "Font Awesome 6 Free-Regular:style=Regular:size=11;2";

                    modules-left = "xworkspaces";
                    modules-center = "xwindow";
                    modules-right = "filesystem memory cpu date powermenu";

                    cursor-click = "pointer";
                    cursor-scroll = "ns-resize";

                    enable-ipc = true;
                };

                "module/xworkspaces" = {
                    type = "internal/xworkspaces";

                    label-active = "%name%";
                    label-active-background = colors.background-alt;
                    label-active-underline= colors.primary;
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

                    format-mounted-prefix = "DISK %{T2}%{T-} ";
                    format-mounted-prefix-foreground = colors.primary;
                    format-mounted = "<label-mounted>";

                    label-mounted = "%used% used";
                };

                "module/memory" = {
                    type = "internal/memory";
                    interval = 2;
                    format-prefix = "RAM %{T2}%{T-} ";
                    format-prefix-foreground = colors.primary;
                    label = "%percentage_used:2%%";
                };

                "module/cpu" = {
                    type = "internal/cpu";
                    interval = 2;
                    format-prefix = "CPU %{T2}%{T-} ";
                    format-prefix-foreground = colors.primary;
                    label = "%percentage:2%%";
                };

            #     "network-base" = {
            #         type = "internal/network";
            #         interval = 5;
            #         format-connected = "<label-connected>";
            #         format-disconnected = "<label-disconnected>";
            #         label-disconnected = "%{F#F0C674}%ifname%%{F#707880} disconnected";
            #     };

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
}
