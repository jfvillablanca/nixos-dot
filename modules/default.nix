{ lib, ... }:
let
    zoxide = import ./zoxide {};
    zsh = import ./zsh {};

    modules = [
        zoxide
        zsh
    ];
in
lib.lists.foldl lib.recursiveUpdate {} modules
