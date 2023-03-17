{ pkgs, lib, ... }:
let
    alacritty = import ./alacritty {};
    neovim = import ./neovim { inherit pkgs; };
    starship = import ./neovim { inherit lib; };
    direnv = import ./direnv {};
    zoxide = import ./zoxide {};
    zellij = import ./zellij {};
    exa = import ./exa {};
    zsh = import ./zsh {};

    modules = [
        alacritty
        starship
        direnv
        neovim
        zoxide
        zellij
        exa
        zsh
    ];
in
lib.lists.foldl lib.recursiveUpdate {} modules
