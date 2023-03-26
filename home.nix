{ config, pkgs, lib, ... }:
let
    isWayland = false;
in
{
    # TODO: 
    # - xrandr autodetect?
    # - configure i3 layout default

    imports = [ ({ ... }: import ./modules { inherit config pkgs lib isWayland; }) ];

    home = {
        username = "jmfv";
        homeDirectory = "/home/jmfv";
        stateVersion = "22.11";
        packages = with pkgs; [
            # Terminal
            fzf                             # Fuzzy search
            xplr                            # TUI file explorer
            imv                             # Image viewer
            tldr                            # Lazy man's help/man page
            manix                           # Nix document searcher

            # Utils
            xclip                           # Clipboard
            ripgrep                         # Grep alternative
            fd                              # Find
            scrot                           # Screenshot utility
            killall                         # Kill processes
            ncdu                            # NCurses Disk Usage
            imagemagick                     # Edit, compose, convert bmp

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

    services = {
        picom = {
            enable = true;
            activeOpacity = 0.95;
            inactiveOpacity = 0.7;
            backend = "xrender";

            # NOTE: Don't know how to use glx in QEMU/KVM machine
            # settings = {
            #     wintypes = {
            #         normal = { blur-background = true; };
            #     };
            #     blur = {
            #         method = "dual_kawase";
            #         strength = 2;
            #     };
            # };
        };
    };

    xsession = {
        enable = true;
        initExtra = "spice-vdagent &"; # starts the x11 spice-vdagent manually especially if running on none+someWM
    };

    xdg = {
        enable = true;
    };
}
