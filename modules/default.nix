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

    # Window Manager
    ./wm/rofi
  ];

  x11Modules = [
    # ./wm/xmonad 
    ./wm/autorandr
    ./wm/polybar
    ./wm/i3status-rust
    ./wm/i3
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
