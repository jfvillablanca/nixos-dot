{ pkgs, ... }:
{
    xsession = {
        windowManager = {
            xmonad = {
                enable = true;
                enableContribAndExtras = true;
                config = pkgs.writeText "xmonad.hs" ''
                    ${ builtins.readFile ./xmonad.hs }
                '';
            };
        };
    };
}
