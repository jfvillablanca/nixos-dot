{ config, pkgs, lib, isWayland, ... }:
let
  modules = [
    ./wallpapers
    ./alacritty
    (_: import ./neovim { inherit config pkgs; })
    ./starship
    ./direnv
    ./zoxide
    ./zellij
    ./exa
    ./zsh
    (_: import ./bash { inherit isWayland; })
    ./gitui
    ./git
    ./bat
    (_: import ./flameshot { inherit config; })
    ./fzf
    (_: import ./tmux { inherit pkgs; })
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
    ./wm/wayland
    ./wm/wayland/sway
    ./wm/wayland/waybar
  ];
in
{
  imports = modules ++
    (if isWayland then
      waylandModules
    else
      x11Modules);
}
