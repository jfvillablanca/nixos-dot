{ config, pkgs, lib, isWayland, user, ... }:
{
  # TODO: 
  # - xrandr autodetect?
  # - configure i3 layout default
    # Move colorschemes/themes to separate module and import instead of prop drill

  imports = [ ({ ... }: import ./modules { inherit config pkgs lib isWayland; }) ];

  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";
    stateVersion = "22.11";
    packages = with pkgs; [
      # Terminal
      fzf                               # Fuzzy search
      xplr                              # TUI file explorer
      imv                               # Image viewer
      tldr                              # Lazy man's help/man page
      manix                             # Nix document searcher

      # Terminal Utils
      ripgrep                           # Grep alternative
      fd                                # Find
      killall                           # Kill processes
      ncdu                              # NCurses Disk Usage
      imagemagick                       # Edit, compose, convert bmp

      # Browser
      (if !isWayland then firefox else firefox-wayland)

      # Misc
      neofetch

      # Utils
      pavucontrol
      pamixer
    ];
    sessionVariables = {
      TERMINAL = "alacritty";
      EDITOR = "nvim";
      VISUAL = "nvim";
      GIT_EDITOR = "nvim";
      MANPAGER = "nvim +Man!";
    };
  };

  programs = {
  };

  services = {
  };

  xsession = {
    enable = !isWayland;
    initExtra = "spice-vdagent &"; # starts the x11 spice-vdagent manually especially if running on none+someWM
  };

  xdg = {
    enable = true;
  };
}
