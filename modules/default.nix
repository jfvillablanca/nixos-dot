{ pkgs, lib, ... }:
let
    neovim = import ./neovim { inherit pkgs; };
    direnv = import ./direnv {};
    zoxide = import ./zoxide {};
    zellij = import ./zellij {};
    exa = import ./exa {};
    zsh = import ./zsh {};

    modules = [
        direnv
        neovim
        zoxide
        zellij
        exa
        zsh
    ];
in
lib.lists.foldl lib.recursiveUpdate {} modules
