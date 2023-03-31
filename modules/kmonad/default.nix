{ pkgs, ... }:
{
    xdg.configFile."kmonad" = {
        source = ./kbd;
        recursive = true;
    };

    home.packages = with pkgs; [
        haskellPackages.kmonad
    ];
}
