{ pkgs, ... }:
{
    programs = {
        rofi = {
            enable = true;
            terminal = "${pkgs.alacritty}/bin/alacritty";
            configPath = "$XDG_CONFIG_HOME/rofi/config.rasi";
            font = "JetBrainsMono Nerd Font 13";
            location = "center";
        };
    };
}
