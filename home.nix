{ config, pkgs, lib, user, ... }:
{
  # TODO: 
  # - xrandr autodetect?
  # - configure i3 layout default
  # Move colorschemes/themes to separate module and import instead of prop drill


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
      trashy # Trash in cli
      htop # System monitor with explicit processes
      gotop # System monitor but cool graphics
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

  programs = { };

  services = { };

  xdg = {
    enable = true;
  };
}
