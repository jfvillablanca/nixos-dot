{ pkgs, ... }:
{
  home.username = "jmfv";
  home.homeDirectory = "/home/jmfv";

  home.stateVersion = "22.11";

  # Packages to be installed
  home.packages = with pkgs; [
    # Languages
    rustup
    nodejs
    go
    python311
    python311Packages.pip
    nodePackages_latest.typescript

    # Terminal
    exa
    fzf
    gitui
    zellij

    # Utils
    xclip
    ripgrep
    fd

    # Development
    nil
    stylua
    nodePackages_latest.prettier

    # Browser
    librewolf
  ];
  
  programs = {
    zsh = {
        enable = true;
        enableAutosuggestions = true;
        enableCompletion = true;
        enableSyntaxHighlighting = true;
    };

    zoxide = {
        enable = true;
        enableZshIntegration = true;
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
            "$nix_shell"
            "$shlvl"
            "$git_branch"
            "$git_state"
            "$git_status"
            "$git_metrics"
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
                format = "[$symbol $state( ($name))](bold crystalblue) ";
                symbol = " ";
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
            shell = "zsh";
        };
    };

    neovim = {
        enable = true;
        # package = pkgs.neovim-nightly;
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
  };

}
