{pkgs, ...}: {
  imports = [
    ../../homeModules/system/xdg.nix
  ];

  myHomeModules = {
    window-manager = {
      enable = true;
      wm = "i3";
    };

    git.enable = true;
    gh.enable = false;
    neovim.enable = true;

    alacritty.enable = false;
    wezterm.enable = true;

    atuin.enable = false;
    bat.enable = false;
    tmux.enable = true;
    btop.enable = true;
    flameshot.enable = true;
    fd.enable = true;
    ripgrep.enable = true;
    fzf.enable = true;
    gitui.enable = false;
    eza.enable = true;
    direnv.enable = true;
    zoxide.enable = true;
    starship.enable = true;
    zellij.enable = false;

    bash.enable = true;
    fish.enable = true;
    zsh.enable = false;

    firefox.enable = false;
  };

  home = {
    packages = with pkgs; [
      # Terminal
      tldr # Lazy man's help/man page
      nixpkgs-review # For reviewing PRs to nixpkgs repository
      trashy # Trash in cli
      killall # Kill processes
      ncdu # NCurses Disk Usage
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
}
