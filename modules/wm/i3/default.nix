{ pkgs, lib, ... }:
{
    xsession = {
        windowManager = {
            i3 = {
                enable = true;
                config = rec {
                    modifier = "Mod4";
                    gaps = {
                        outer = 1;
                        inner = 7;
                    };
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
                        "${modifier}+t" = "exec ${pkgs.alacritty}/bin/alacritty";
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
