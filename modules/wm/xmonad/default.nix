{ pkgs, ... }:
{
    xsession = {
        windowManager = {
            xmonad = {
                enable = false;
                enableContribAndExtras = true;
                config = pkgs.writeText "xmonad.hs" ''
                    ${ builtins.readFile ./xmonad.hs }
                '';
            };
        };
    };
}
