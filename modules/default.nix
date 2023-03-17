{ pkgs, lib, ... }:
let
    neovim = import ./neovim { inherit pkgs; };
    direnv = import ./direnv {};
    zoxide = import ./zoxide {};
    zsh = import ./zsh {};

    modules = [
        direnv
        neovim
        zoxide
        zsh
    ];
in
lib.lists.foldl lib.recursiveUpdate {} modules
