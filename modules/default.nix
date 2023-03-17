{ pkgs, lib, ... }:
let
    neovim = import ./neovim { inherit pkgs; };
    zoxide = import ./zoxide {};
    zsh = import ./zsh {};

    modules = [
        neovim
        zoxide
        zsh
    ];
in
lib.lists.foldl lib.recursiveUpdate {} modules
