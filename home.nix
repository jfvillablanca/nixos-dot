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
    git = {
        enable = true;
        extraConfig = {
            init.defaultBranch = "main";
            user = {
                name = "jfvillablanca";
                email = "31008330+jfvillablanca@users.noreply.github.com";
            };
            color.ui = "auto";
        };
        delta = {
            enable = true;
            options = {
                features = "decorations";
                decorations = {
                  commit-decoration-style = "#7FB4CA ol";
                  commit-style = "raw";
                  file-style = "omit";
                  hunk-header-decoration-style = "#7FB4CA box";
                  hunk-header-file-style = "#E46876";
                  hunk-header-line-number-style = "#98BB6C";
                  hunk-header-style = "file line-number syntax";
                };
            };
        };
    };

    gitui = {
        enable = true;
        theme = 
        ''
        (
            /* Color Palette: rebelot/kanagawa.nvim */
            selected_tab: Reset,
            command_fg: Rgb(220, 215, 186),              // #DCD7BA (fujiWhite) 
            selection_bg: Rgb(84, 84, 109),              // #54546D (sumiInk4)
            selection_fg: White,
            cmdbar_bg: Rgb(84, 84, 109),                 // #54546D (sumiInk4) 
            cmdbar_extra_lines_bg: Rgb(84, 84, 109),     // #54546D (sumiInk4) 
            disabled_fg: Rgb(114, 113, 105),             // #727169 (fujiGray)  
            diff_line_add: Green,
            diff_line_delete: Red,
            diff_file_added: LightGreen,
            diff_file_removed: LightRed,
            diff_file_moved: LightMagenta,
            diff_file_modified: Yellow,
            commit_hash: Rgb(210, 126, 153),             // #D27E99 (sakuraPink)
            commit_time: Rgb(127, 180, 202),             // #7FB4CA (springBlue)
            commit_author: Rgb(152, 187, 108),           // #98BB6C (springGreen)
            danger_fg: Red,
            push_gauge_bg: Blue,
            push_gauge_fg: Reset,
            tag_fg: LightMagenta,
            branch_fg: Rgb(230, 195, 132),               // #E6C384 (carpYellow) 

            /* Default Colors */

            /* selected_tab: Reset, */
            /* command_fg: White, */
            /* selection_bg: Blue, */
            /* selection_fg: White, */
            /* cmdbar_bg: Blue, */
            /* cmdbar_extra_lines_bg: Blue, */
            /* disabled_fg: DarkGray, */
            /* diff_line_add: Green, */
            /* diff_line_delete: Red, */
            /* diff_file_added: LightGreen, */
            /* diff_file_removed: LightRed, */
            /* diff_file_moved: LightMagenta, */
            /* diff_file_modified: Yellow, */
            /* commit_hash: Magenta, */
            /* commit_time: LightCyan, */
            /* commit_author: Green, */
            /* danger_fg: Red, */
            /* push_gauge_bg: Blue, */
            /* push_gauge_fg: Reset, */
            /* tag_fg: LightMagenta, */
            /* branch_fg: LightYellow, */
        )
        '';
    };

    bat = {
        enable = true;
        config = {
            # FIXME: dracula is not recognized as a theme
            theme = "dracula";
        };
        themes = {
          dracula = builtins.readFile (pkgs.fetchFromGitHub {
            owner = "dracula";
            repo = "sublime"; # Bat uses sublime syntax for its themes
            rev = "26c57ec282abcaa76e57e055f38432bd827ac34e";
            sha256 = "019hfl4zbn4vm4154hh3bwk6hm7bdxbr1hdww83nabxwjn99ndhv";
          } + "/Dracula.tmTheme");
        };
    };

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
