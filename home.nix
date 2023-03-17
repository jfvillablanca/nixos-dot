{ pkgs, lib, ... }:
let
    modules = import ./modules { inherit pkgs; inherit lib; };
in
lib.recursiveUpdate 
modules
{
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
            fzf

            # Utils
            xclip
            ripgrep
            fd
            scrot                           # Screenshot utility

            # Development
            nil
            stylua
            nodePackages_latest.prettier

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
    rofi = {
        enable = true;
        terminal = "${pkgs.alacritty}/bin/alacritty";
    };
    
    # Need to organize with services.autorandr
    autorandr = {
        enable = true;
    };
  };

  services = {
    # Need to organize with programs.autorandr
    autorandr = {
        enable = true;
    };

    polybar = {
        enable = true;
        script = "polybar bar &";
    };
  };

    xsession = {
        enable = true;
        initExtra = "spice-vdagent &"; # starts the x11 spice-vdagent manually especially if running on none+someWM
        windowManager = {
            xmonad = {
                enable = true;
                enableContribAndExtras = true;
                config = pkgs.writeText "xmonad.hs" ''
                    ${builtins.readFile ./modules/wm/xmonad/xmonad.hs}
                '';
            };
        };
    };
}
