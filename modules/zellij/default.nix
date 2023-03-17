{ ... }:
{
    programs = {
        zellij = {
            enable = true;
            settings = {
                default_shell = "zsh";
                ui = {
                    pane_frames.rounded_corners = true;
                };
                themes = {
                    kanagawa = {
                        fg = "#DCD7BA";
                        bg = "#2A2A37";
                        red = "#C34043";
                        green = "#76946A";
                        yellow = "#FF9E3B";
                        blue = "#7E9CD8";
                        magenta = "#957FB8";
                        orange = "#FFA066";
                        cyan = "#7FB4CA";
                        black = "#2A2A37";
                        white = "#DCD7BA";
                    };
                };
                theme = "kanagawa";
            };
        };
    };
}
