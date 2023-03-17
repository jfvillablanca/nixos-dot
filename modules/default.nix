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

    modules = [
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
    ];
in
lib.lists.foldl lib.recursiveUpdate {} modules
