{ config, pkgs, ... }:

{
  home.username = "jmfv";
  home.homeDirectory = "/home/jmfv";

  home.stateVersion = "22.11";

  # Packages to be installed
  home.packages = with pkgs; [
    # Essentials
    alacritty
    neovim

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
    starship

    # Utils
    ripgrep
    fd

    # Development
    nil
    stylua
    shfmt
    nodePackages_latest.prettier

    # Browser
    librewolf
  ];
  
}
