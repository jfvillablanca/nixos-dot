{ config, pkgs, ... }:
let
    user = "jmfv";
    etcProfile = "/etc/profiles/per-user/${user}/";
    
    nvim-nightly = 
        (import (builtins.fetchTarball 
        {
            url = "https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz";
            sha256 = "0a79rnzh6snbdnanwjvh0yhlv2v66mg40k1jhh96sa9x7s8xj0nf";
        }
        ));     
in
{
  nixpkgs = {
      overlays = [
        nvim-nightly
    ];
  };

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
  
  services = {
    clipmenu = {
        enable = true;
    };
  };

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
        package = nvim-nightly.neovim-nightly;
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
  };

}
