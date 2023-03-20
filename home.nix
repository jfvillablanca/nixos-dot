{ config, pkgs, lib, ... }:
let
    modules = import ./modules { inherit config pkgs lib; };
in
lib.recursiveUpdate 
modules
{
    # TODO: 
    # - partial: configure nvim to be reproducible. 
    #   - done: symlinked nvim config in ./modules/neovim/nvim to ~/.config/nvim
    #   - pending: lsp needs to find the bin paths from the nix store, somehow
    # - xrandr autodetect?
    # - configure zellij keybinds for gitui
    # - configure i3 layout default
    # - refactor modules/default.nix to use imports []


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

    services = {
        picom = {
            enable = true;
            activeOpacity = 0.95;
            inactiveOpacity = 0.7;
            backend = "xrender";

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
}
