{ config, pkgs, lib, ... }:
{
    imports = [
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
        ./wm/autorandr 
        ./wm/polybar 
        ./wm/i3status-rust 
        ./wm/rofi 
        ./wm/xmonad 
        ./wm/i3 
    ];
}
