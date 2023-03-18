{ pkgs, lib, ... }:
let
    modules = import ./modules { inherit pkgs; inherit lib; };
    activeWM = "spectrwm"; # or xmonad
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
        xmobar = {
            enable = false;
            extraConfig = ''
            Config 
            { overrideRedirect = False
            , font     = "xft:iosevka-9"
            , bgColor  = "#5f5f5f"
            , fgColor  = "#f8f8f2"
            , position = TopW L 90
            , commands = [ Run Cpu
                             [ "-L", "3"
                             , "-H", "50"
                             , "--high"  , "red"
                             , "--normal", "green"
                             ] 10
                         , Run Alsa "default" "Master"
                             [ "--template", "<volumestatus>"
                             , "--suffix"  , "True"
                             , "--"
                             , "--on", ""
                             ]
                         , Run Memory ["--template", "Mem: <usedratio>%"] 10
                         , Run Swap [] 10
                         , Run Date "%a %Y-%m-%d <fc=#8be9fd>%H:%M</fc>" "date" 10
                         , Run XMonadLog
                         ]
            , sepChar  = "%"
            , alignSep = "}{"
            , template = "%XMonadLog% }{ %alsa:default:Master% | %cpu% | %memory% * %swap% | %date% "
            }
            '';
        };
    };

    services = {};

    xsession = {
        enable = true;
        initExtra = "spice-vdagent &"; # starts the x11 spice-vdagent manually especially if running on none+someWM

        windowManager.command = "${pkgs.${activeWM}}/bin/${activeWM}"; # set the active window manager if multiple WMs are installed

        windowManager = {
            spectrwm = {
                enable = true;
                settings = {
                    modkey = "Mod4";
                    workspace_limit = 8;
                };
            };
        };
    };
}
