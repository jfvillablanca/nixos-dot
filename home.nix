{ pkgs, lib, ... }:
let
    modules = import ./modules { inherit pkgs; inherit lib; };
in
lib.recursiveUpdate 
modules
{
    # TODO: 
    # - configure nvim to be reproducible. 
    # - xrandr autodetect?
    # - how to wallpaper with feh and git
    home = {
        username = "jmfv";
        homeDirectory = "/home/jmfv";
        stateVersion = "22.11";
        packages = with pkgs; [
            # Languages
            rustup
            nodejs
            go
            python311
            python311Packages.pip
            nodePackages_latest.typescript

            # Terminal
            fzf                             # Fuzzy search
            xplr                            # TUI file explorer
            imv                             # Image viewer
            tldr                            # Lazy man's help/man page

            # Utils
            xclip                           # Clipboard
            ripgrep                         # Grep alternative
            fd                              # Find
            scrot                           # Screenshot utility
            killall                         # Kill processes
            ncdu                            # NCurses Disk Usage
            imagemagick                     # Edit, compose, convert bmp

            # Development
            nil
            stylua
            nodePackages_latest.prettier
            haskellPackages.haskell-language-server

            # Browser
            librewolf

            # Misc
            neofetch
          ];
        sessionVariables = {
            TERMINAL = "alacritty"; 
            EDITOR = "nvim";
            VISUAL = "nvim";
            GIT_EDITOR = "nvim";
            MANPAGER =  "nvim +Man!";
        };
    };

    programs = {
        feh.enable = true;
    };

    services = {};

    xsession = {
        enable = true;
        initExtra = "spice-vdagent &"; # starts the x11 spice-vdagent manually especially if running on none+someWM
    };
}
