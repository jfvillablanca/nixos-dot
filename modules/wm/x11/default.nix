{ pkgs, ... }:
{
  home.packages = with pkgs; [
    xclip                           # Clipboard
    scrot                           # Screenshot utility
    arandr                          # GUI fox xrandr
  ];
  programs = {
    feh.enable = true;
  };
}
