{ ... }:
{
    programs = {
        alacritty = {
            enable = true;
            settings = {
                window = {
                    padding.x = 5;
                    padding.y = 5;
                    opacity = 1.0;
                };
                font = {
                    size = 14.0;
                    normal = {
                        family = "JetBrainsMono Nerd Font";
                        style = "Regular";
                    };
                    bold = {
                        family = "JetBrainsMono Nerd Font";
                        style = "SemiBold";
                    };
                    bold_italic = {
                        family = "JetBrainsMono Nerd Font";
                        style = "SemiBold Italic";
                    };
                    italic = {
                        family = "JetBrainsMono Nerd Font";
                        style = "Italic";
                    };
                };
                colors = {
                    primary = {
                        foreground = "#dcd7ba";
                        background = "#1f1f28";
                    };
                    normal = {
                        black=   "#090618";
                        red=     "#c34043";
                        green=   "#76946a";
                        yellow=  "#c0a36e";
                        blue=    "#7e9cd8";
                        magenta= "#957fb8";
                        cyan=    "#6a9589";
                        white=   "#c8c093";
                    };
                    bright = {
                        black=   "#727169";
                        red=     "#e82424";
                        green=   "#98bb6c";
                        yellow=  "#e6c384";
                        blue=    "#7fb4ca";
                        magenta= "#938aa9";
                        cyan=    "#7aa89f";
                        white=   "#dcd7ba";
                    };
                    selection = {
                        foreground = "#c8c093";
                        background = "#2d4f67";
                    };
                    # indexed_colors = {};
                };
                shell = "zsh";
            };
        };
    };
}
