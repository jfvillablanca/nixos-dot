{ pkgs, lib, ... }:
{
    xsession = {
        windowManager = {
            i3 = {
                enable = true;
                config = rec {
                    modifier = "Mod4";
                    gaps = {
                        outer = 5;
                        inner = 5;
                    };
                    window.border = 0;
                    bars = [
                    {
                        statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-top.toml";
                        position = "top";
                    }
                    ];
                    keybindings = lib.mkOptionDefault {
                        "${modifier}+t" = "exec ${pkgs.alacritty}/bin/alacritty";
                    };
                    menu = "${pkgs.rofi}/bin/rofi";
                    fonts = {
                        names = [ "JetBrainsMono Nerd Font" ];
                        style = "SemiBold";
                        size = 11.0;
                    };
                };
            };
        };
    };
}
