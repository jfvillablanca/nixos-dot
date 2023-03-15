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

    bat = {
        enable = true;
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
