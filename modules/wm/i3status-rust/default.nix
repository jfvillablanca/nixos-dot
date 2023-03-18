{ ... }:
{
    programs = {
        i3status-rust = {
            enable = true;
            bars.top = {
                theme = "nord-dark";
                icons = "awesome6";
                blocks = [
                {
                  block = "time";
                  interval = 60;
                  format = "%a %d/%m %k:%M";
                }
                {
                    block = "disk_space";
                    click = {
                        button = "left";
                        update = true;
                    };
                    info_type = "available";
                    alert_unit = "GB";
                    alert = 10.0;
                    warning = 15.0;
                    format = " $icon $available ";
                    format_alt = " $icon $available / $total ";
                }
                ];
            };
        };
    };
}
