{
  pkgs,
  user,
  ...
}: {
  myHomeModules = {
    git.enable = true;

    alacritty.enable = false;
    wezterm.enable = true;

    bat.enable = false;
    tmux.enable = true;
    btop.enable = true;
    fish.enable = true;
    flameshot.enable = true;
    fzf.enable = true;
    gitui.enable = false;
    eza.enable = true;
    direnv.enable = true;
    zoxide.enable = true;
    starship.enable = true;
    zellij.enable = false;
    zsh.enable = false;
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
      imagemagick # Edit, compose, convert bmp
      unzip # Zip utility
      zip # Zip utility

      # Misc
      neofetch # System lookup

      # Utils
      pavucontrol # Volume control UI
      pamixer # PipeWire CLI tool
      onboard # On-screen keyboard
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

  xdg = {
    enable = true;
    portal = {
      enable = true;
      extraPortals = with pkgs; [xdg-desktop-portal-gtk];
      config = {
        common.default = ["gtk"];
        hyprland.default = ["gtk" "hyprland"];
      };
    };
  };
}
