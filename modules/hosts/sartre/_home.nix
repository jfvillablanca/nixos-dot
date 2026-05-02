{
  config,
  inputs,
  lib,
  pkgs,
  base16Scheme,
  ...
}: {
  imports =
    [
      inputs.nix-colors.homeManagerModules.default
      # inputs.impermanence.nixosModules.home-manager.impermanence
    ]
    ++ (with inputs.self.modules.homeManager; [
      alacritty
      bash
      bat
      btop
      delta
      direnv
      eza
      fd
      fish
      fzf
      gh
      git
      gitui
      neovim
      ripgrep
      starship
      tmux
      wezterm
      yazi
      zellij
      zoxide
      zsh
    ]);

  colorScheme = inputs.nix-colors.colorSchemes.${base16Scheme};

  myHomeModules = {





  };

  stylix = {
    targets = {
    };
  };

  home = {
    packages = with pkgs; [
      # Terminal
      tldr # Lazy man's help/man page
      trashy # Trash in cli
      killall # Kill processes
      ncdu # NCurses Disk Usage
      unzip # Zip utility
      zip # Zip utility
      lazydocker # Docker and Docker compose management utility
      wl-clipboard

      # Browser
      # Alternate browser for running web apps that are "unoptimized" in Firefox (or can't play with Firefox's hardened security policies)
      # google-chrome

      # Misc
      neofetch # System lookup

      # Utils
      # pavucontrol # Volume control UI
      # pamixer # PipeWire CLI tool
      # file-roller # File archiving
      # eog # GUI image viewer
      # onboard # On-screen keyboard
      # zathura # PDF Viewer

      # GUI
      # xfce.thunar # Xfce file manager
      # xfce.thunar-volman # Removable media Thunar extension

              (import ../../../customPkgs {inherit pkgs;}).vf
      (import ../../../customPkgs {inherit pkgs;}).use
    ];
    sessionVariables = {
      TERMINAL = "wezterm";
      EDITOR = "nvim";
      VISUAL = "nvim";
      GIT_EDITOR = "nvim";
      MANPAGER = "nvim +Man!";
    };
  };

  programs = {};

  services = {};
}
