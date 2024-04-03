{
  pkgs,
  user,
  ...
}: {
  imports = [
    ../../homeModules/system/xdg.nix

    ../../homeModules/system/wallpapers
  ];

  myHomeModules = {
    window-manager = {
      enable = true;
      wm = "i3";
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
    lf.enable = false;
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
      xplr # TUI file explorer
      imv # Image viewer
      tldr # Lazy man's help/man page
      manix # Nix document searcher
      nixpkgs-review # For reviewing PRs to nixpkgs repository
      trashy # Trash in cli
      ripgrep # Grep alternative
      fd # Find
      killall # Kill processes
      ncdu # NCurses Disk Usage
      imagemagick # Edit, compose, convert bmp
      unzip # Zip utility
      zip # Zip utility
      lazydocker # Docker and Docker compose management utility

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
      simplescreenrecorder # Screen recorder
      gnome.file-roller # File archiving
      gnome.eog # GUI image viewer
      onboard # On-screen keyboard
      zathura # PDF Viewer

      # GUI
      lxappearance # theming and fonts for gtk applications
      xfce.thunar # Xfce file manager
      xfce.thunar-volman # Removable media Thunar extension

      # Themes and Icons
      catppuccin-gtk
      catppuccin-papirus-folders
      nordic
      rose-pine-gtk-theme
      sierra-gtk-theme
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
