{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      wl-clipboard                              # Clipboard
      sway-contrib.grimshot                     # Screenshot utility
      swaylock                                  # Lock screen
    ];
  };
  programs = { };
}
