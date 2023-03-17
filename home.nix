{ pkgs, lib, ... }:
let
    modules = import ./modules { inherit lib; };
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

    zellij = {
        enable = true;
        settings = {
            default_shell = "zsh";
            ui = {
                pane_frames.rounded_corners = true;
            };
            themes = {
                kanagawa = {
                    fg = "#DCD7BA";
                    bg = "#2A2A37";
                    red = "#C34043";
                    green = "#76946A";
                    yellow = "#FF9E3B";
                    blue = "#7E9CD8";
                    magenta = "#957FB8";
                    orange = "#FFA066";
                    cyan = "#7FB4CA";
                    black = "#2A2A37";
                    white = "#DCD7BA";
                };
            };
            theme = "kanagawa";
        };
    };

    exa = {
        enable = true;
        git = true;
        icons = true;
        extraOptions = [
            "--group-directories-first"
        ];
        enableAliases = true;
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

    starship = {
        enable = true;
        enableZshIntegration = true;
        settings = 
        {
            format = pkgs.lib.concatStrings [
            "$username"
            "$hostname"
            "$directory"
            "$shlvl"
            "$git_branch"
            "$git_state"
            "$git_status"
            "$git_metrics"
            "$nix_shell"
            "$fill"
            "$nodejs"
            "$rust"
            "$jobs"
            "$memory_usage"
            "$line_break"
            "$character"
            ];

            add_newline = false;

            palette = "kanagawa";

            palettes.kanagawa = {
                oldwhite = "#c8c093";
                roninyellow = "#ff9e3b";
                autumngreen = "#76946A";
                crystalblue = "#7E9CD8";
                surimiorange = "#FFA066";
                samuraired = "#E82424";
                autumnred = "#C34043";
            };

            username = {
                style_user = "autumngreen bold";
                style_root = "black bold";
                format = "[$user]($style) ";
                disabled = false;
                show_always = true;
            };

            hostname = {
                ssh_only = false;
                format = "[$ssh_symbol](bold cyan)[$hostname](bold roninyellow) ";
                trim_at = ".companyname.com";
                disabled = false;
            };

            directory = {
                style = "crystalblue";
                read_only = " ";
                truncation_length = 1;
                truncate_to_repo = false;
            };

            git_branch = {
                symbol = " ";
                format = "[$symbol$branch]($style) ";
                style = "surimiorange";
            };

            git_state = {
                format = "([$state( $progress_current/$progress_total)]($style)) ";
                style = "bright-black";
            };

            git_status = {
                format = ''([\[$all_status$ahead_behind\]]($style) )'';
                style = "cyan";
            };

            git_metrics.disabled = false;

            fill.symbol = " ";

            nodejs = {
                format = "[$symbol($version )]($style)";
                disabled = true;
            };

            rust = {
                symbol = " ";
            };

            nix_shell = {
                disabled = false;
                impure_msg = "[impure shell](bold autumnred)";
                pure_msg = "[pure shell](bold autumngreen)";
                unknown_msg = "[unknown shell](bold roninyellow)";
                format = ''[$symbol \[$state\]( ($name))](crystalblue) '';
                symbol = "";
            };

            shlvl = {
              disabled = false;
              symbol = "ﰬ";
              style = "samuraired bold";
            };

            jobs = {
                symbol = "";
                style = "bold red";
                number_threshold = 1;
                format = "[$symbol]($style)";
            };

            memory_usage = {
                symbol = " ";
            };

            character = {
                success_symbol = "[❯](purple)";
                error_symbol = "[❯](red)";
                vicmd_symbol = "[❮](green)";
            };
        };
    };

    alacritty = {
        enable = true;
        settings = {
            window = {
                padding.x = 5;
                opacity = 0.9;
            };
            font = {
                size = 14.0;
                normal = {
                    family = "JetBrainsMono Nerd Font";
                    style = "Regular";
                };
                bold = {
                    family = "JetBrainsMono Nerd Font";
                    style = "SemiBold";
                };
                bold_italic = {
                    family = "JetBrainsMono Nerd Font";
                    style = "SemiBold Italic";
                };
                italic = {
                    family = "JetBrainsMono Nerd Font";
                    style = "Italic";
                };
            };
            colors = {
                primary = {
                    foreground = "#dcd7ba";
                    background = "#1f1f28";
                };
                normal = {
                    black=   "#090618";
                    red=     "#c34043";
                    green=   "#76946a";
                    yellow=  "#c0a36e";
                    blue=    "#7e9cd8";
                    magenta= "#957fb8";
                    cyan=    "#6a9589";
                    white=   "#c8c093";
                };
                bright = {
                    black=   "#727169";
                    red=     "#e82424";
                    green=   "#98bb6c";
                    yellow=  "#e6c384";
                    blue=    "#7fb4ca";
                    magenta= "#938aa9";
                    cyan=    "#7aa89f";
                    white=   "#dcd7ba";
                };
                selection = {
                    foreground = "#c8c093";
                    background = "#2d4f67";
                };
                # indexed_colors = {};
            };
            shell = "zsh";
        };
    };

    neovim = {
        enable = true;
        package = pkgs.neovim-nightly;
        defaultEditor = true;
        vimAlias = true;
        withNodeJs = true;
        withPython3 = true;

        extraPackages = with pkgs; [
            shfmt
        ];

        plugins = with pkgs.vimPlugins; [
            nvim-lspconfig
            mason-lspconfig-nvim
            mason-nvim
        ];
    };

    direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
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
