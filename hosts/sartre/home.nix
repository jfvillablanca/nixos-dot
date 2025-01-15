{
  config,
  inputs,
  lib,
  pkgs,
  base16Scheme,
  ...
}: {
  imports = [
    inputs.nix-colors.homeManagerModules.default
    # inputs.impermanence.nixosModules.home-manager.impermanence

    ../../homeModules/system/xdg.nix
    ../../homeModules/system/wallpapers
  ];

  colorScheme = inputs.nix-colors.colorSchemes.${base16Scheme};

  myHomeModules = {
    window-manager = {
      enable = false;
      wm = "hyprland";
      monitors = [
        {
          name = "eDP-1";
          isPrimary = true;
          width = 1920;
          height = 1080;
          x = 0;
          y = 0;
        }
      ];
    };

    git.enable = true;
    gh.enable = true;
    neovim.enable = true;

    alacritty.enable = true;
    wezterm.enable = true;

    atuin.enable = false;
    bat.enable = true;
    tmux.enable = true;
    btop.enable = true;
    flameshot.enable = false;
    fd.enable = true;
    ripgrep.enable = true;
    fzf.enable = true;
    gitui.enable = true;
    yazi.enable = true;
    eza.enable = true;
    direnv.enable = true;
    zoxide.enable = true;
    starship.enable = true;
    zellij.enable = true;

    bash.enable = true;
    fish.enable = true;
    zsh.enable = true;

    firefox.enable = true;
  };

  stylix = {
    targets = {
      waybar.enable = false;
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
      pavucontrol # Volume control UI
      pamixer # PipeWire CLI tool
      file-roller # File archiving
      eog # GUI image viewer
      onboard # On-screen keyboard
      zathura # PDF Viewer

      # GUI
      # xfce.thunar # Xfce file manager
      # xfce.thunar-volman # Removable media Thunar extension

      (
        lib.mkIf (
          config.myHomeModules.neovim.enable
          && config.myHomeModules.bat.enable
          && config.myHomeModules.fd.enable
          && config.myHomeModules.ripgrep.enable
        )
        (import ../../customPkgs {inherit pkgs;}).vf
      )
      (import ../../customPkgs {inherit pkgs;}).use
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
