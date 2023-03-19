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
                  format = {
                      full = " $icon $timestamp.datetime(f:'%a %Y-%m-%d %R', l:en_US) ";
                      short = " $icon $timestamp.datetime(f:%R) ";
                  };
                }
                {
                    block = "disk_space";
                    path = "/";
                    interval = 60.0;
                    info_type = "available";
                    alert_unit = "GB";
                    alert = 20.0;
                    format = " $icon $available ";
                    format_alt = " $icon $available / $total ";
                }
                ];
            };
        };
    };
}
