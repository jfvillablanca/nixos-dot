{ config, pkgs, lib, isWayland, ... }:
let
  modules = [
    ./alacritty
    ({ ... }: import ./neovim { inherit config pkgs; })
    ./starship
    ./direnv
    ./zoxide
    ./zellij
    ./exa
    ./zsh
    ./bash
    ./gitui
    ./git
    ./bat
  ];

  x11Modules = [
    ./wm/x11
    # ./wm/x11/xmonad 
    ./wm/x11/autorandr
    ./wm/x11/polybar
    ./wm/x11/i3status-rust
    ./wm/x11/i3
    ./wm/x11/picom
    ./wm/x11/rofi
  ];

  waylandModules = [
  ];
in
{
  imports = modules ++
    (if isWayland then
      waylandModules
    else
      x11Modules);
}
