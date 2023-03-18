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
