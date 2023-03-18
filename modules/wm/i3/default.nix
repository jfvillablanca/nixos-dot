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
                    bars = [ ];
                    keybindings = lib.mkOptionDefault {
                        "${modifier}+t" = "exec ${pkgs.alacritty}/bin/alacritty";
                    };
                    fonts = [
                    {
                        names = [ "JetBrainsMono Nerd Font" ];
                        style = "SemiBold";
                        size = 11.0;
                    }
                    ];
                };
            };
        };
    };
}
