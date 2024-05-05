{
  inputs,
  pkgs,
  user,
  ...
}: {
  imports = [
    inputs.nix-colors.homeManagerModules.default
    inputs.walker.homeManagerModules.walker

    ../../homeModules/system/xdg.nix

    ../../homeModules/system/wallpapers
  ];

  myHomeModules = {
    window-manager = {
      enable = true;
      wm = "hyprland";
      monitors = [
        {
          # name = "HDMI-1";
          # For Hyprland, `hyperctl monitors` lists it as "HDMI-A-1"
          name = "HDMI-A-1";
          isPrimary = true;
          width = 1920;
          height = 1080;
          x = 0;
          y = 0;
        }
        {
          name = "DP-1";
          width = 1920;
          height = 1080;
          x = 1920;
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
    bat = {
      enable = true;
      theme = "everblush";
    };
    tmux.enable = true;
    btop.enable = true;
    flameshot.enable = true;
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
    zsh.enable = false;

    firefox.enable = true;
  };

  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";
    stateVersion = "22.11";
    packages = with pkgs; [
      # Terminal
      imv # Image viewer
      tldr # Lazy man's help/man page
      manix # Nix document searcher
      nixpkgs-review # For reviewing PRs to nixpkgs repository
      trashy # Trash in cli
      ripgrep # Grep alternative
      fd # Find
      killall # Kill processes
      ncdu # NCurses Disk Usage
      unzip # Zip utility
      zip # Zip utility

      # Browser
      # (if !isWayland then firefox else firefox-wayland)
      # Alternate browser for running web apps that are "unoptimized" in Firefox (or can't play with Firefox's hardened security policies)
      google-chrome

      # Misc
      neofetch # System lookup
      musescore # Music notation and composition
      discord # Communications
      torrential # BitTorrent client

      # Utils
      pavucontrol # Volume control UI
      pamixer # PipeWire CLI tool
      barrier # KVM Switchmy custom node shell env
      vlc # Video player
      gnome.file-roller # File archiving
      gnome.eog # GUI image viewer
      onboard # On-screen keyboard
      zathura # PDF Viewer

      # GUI
      lxappearance # theming and fonts for gtk applications
      xfce.thunar # Xfce file manager
      xfce.thunar-volman # Removable media Thunar extension
    ];
    sessionVariables = {
      TERMINAL = "alacritty";
      EDITOR = "nvim";
      VISUAL = "nvim";
      GIT_EDITOR = "nvim";
      MANPAGER = "nvim +Man!";
    };
  };

  programs = {};

  services = {};
}
