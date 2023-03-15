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
