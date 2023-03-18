{ pkgs, lib, ... }:
{
    xsession = {
        windowManager = {
            i3 = {
                enable = true;
                config = rec {
                    modifier = "Mod4";
                    gaps = {
                        outer = 3;
                        inner = 2;
                    };
                    window.border = 0;
                    bars = [ ];
                    keybindings = lib.mkOptionDefault {
                        "${modifier}+t" = "exec ${pkgs.alacritty}/bin/alacritty";
                    };
                };
            };
        };
    };
}
