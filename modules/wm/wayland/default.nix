{ pkgs, ... }:
{
  home = {
    sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
    };
    packages = with pkgs; [
      wl-clipboard # Clipboard
      sway-contrib.grimshot # Screenshot utility
    ];
  };
  programs = { };
}
