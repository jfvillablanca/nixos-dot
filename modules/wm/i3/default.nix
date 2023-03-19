{ pkgs, lib, ... }:
let
    mod = "Mod4";
    term = "alacritty";
in
{
    xsession = {
        windowManager = {
            i3 = {
                enable = true;
                config = {
                    modifier = mod;
                    terminal = term;
                    gaps = {
                        outer = 1;
                        inner = 7;
                    };
                    startup = [
                    {
                        command = "--no-startup-id picom";
                        notification = false;
                        always = true;
                    }
                    {
                        command = "--no-startup-id feh --bg-fill ~/.config/nixos/.wallpapers/nixos-light-gray.png";
                        notification = false;
                        always = true;
                    }
                    ];
                    window.border = 0;
                    bars = [
                    {
                        position = "top";
                        statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-top.toml";
                        fonts = {
                            names = [ "JetBrainsMono Nerd Font" ];
                            style = "SemiBold";
                            size = 13.0;
                        };
                    }
                    ];
                    keybindings = lib.mkOptionDefault {
                        "${mod}+t" = "exec ${term}";
                    };
                    menu = "exec ${pkgs.rofi}/bin/rofi -show drun";
                    fonts = {
                        names = [ "JetBrainsMono Nerd Font" ];
                        style = "SemiBold";
                        size = 11.0;
                    };
                };
                extraConfig = ''
                set $i3lockwall sh ./lock.sh
                bindsym $mod+Ctrl+Shift+l exec --no-startup-id $i3lockwall
                '';
            };
        };
    };
}
