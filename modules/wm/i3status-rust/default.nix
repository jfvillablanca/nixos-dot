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
                    path = "/";
                    interval = 60.0;
                    info_type = "available";
                    unit = "GB";
                    alert = 20.0;
                }
                ];
            };
        };
    };
}
