{ config, pkgs, lib, isWayland, user, ... }:
{
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

      # Utils
      ripgrep                           # Grep alternative
      fd                                # Find
      killall                           # Kill processes
      ncdu                              # NCurses Disk Usage
      imagemagick                       # Edit, compose, convert bmp

      # Browser
      (if !isWayland then firefox else firefox-wayland)

      # Misc
      neofetch
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
    windowManager.i3 = {
      config.startup = [
        {
          command = "--no-startup-id feh --bg-fill ${config.xdg.configHome}/.wallpapers/kanagawa.jpg";
          notification = false;
          always = true;
        }
      ];
    };
  };

  xdg = {
    enable = true;
  };
}
