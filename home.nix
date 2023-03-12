{ config, pkgs, ... }:
let
    user = "jmfv";
    etcProfile = "/etc/profiles/per-user/${user}/";
in
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

    starship = {
        enable = true;
    };

    alacritty = {
        enable = true;
        settings = {
            shell = "${etcProfile}/bin/zsh";
        };
    };

    neovim = {
        enable = true;
        defaultEditor = true;
        vimAlias = true;
        withNodeJs = true;
        withPython3 = true;

        extraPackages = with pkgs; [
            shfmt
        ];
        extraConfig = ":luafile ~/.config/nvim/init.lua";
    };
  };
}
