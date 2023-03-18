{ pkgs, lib, ... }:
let
    alacritty = import ./alacritty {};
    neovim = import ./neovim { inherit pkgs; };
    starship = import ./starship { inherit lib; };
    direnv = import ./direnv {};
    zoxide = import ./zoxide {};
    zellij = import ./zellij {};
    exa = import ./exa {};
    zsh = import ./zsh {};
    gitui = import ./gitui {};
    git = import ./git {};
    bat = import ./bat { inherit pkgs; };

    # Window Manager
    autorandr = import ./wm/autorandr {};
    polybar = import ./wm/polybar {};
    rofi = import ./wm/rofi { inherit pkgs; };
    xmonad = import ./wm/xmonad { inherit pkgs; };
    i3 = import ./wm/i3 { inherit pkgs; inherit lib;  };

    modules = [
        xmonad
        i3
        autorandr
        polybar
        rofi

        alacritty
        starship
        direnv
        neovim
        zoxide
        zellij
        exa
        zsh
        gitui
        git
        bat
    ];
in
lib.lists.foldl lib.recursiveUpdate {} modules
