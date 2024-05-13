{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../../homeModules/system/xdg.nix

    inputs.nix-colors.homeManagerModules.default
    # inputs.walker.homeManagerModules.walker
    inputs.impermanence.nixosModules.home-manager.impermanence
  ];

  colorScheme = inputs.nix-colors.colorSchemes.gruvbox-material-dark-medium;

  myHomeModules = {
    window-manager = {
      enable = false;
      wm = "hyprland";
      monitors = [
        {
          name = "Virtual-1";
          isPrimary = true;
          width = 1411;
          height = 856;
          x = 0;
          y = 0;
        }
      ];
    };

    git.enable = true;
    gh.enable = true;
    neovim.enable = true;

    alacritty.enable = false;
    wezterm.enable = true;

    atuin.enable = false;
    bat.enable = true;
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

      # still using xfce at the moment
      xclip

      (
        lib.mkIf (
          config.myHomeModules.neovim.enable
          && config.myHomeModules.bat.enable
          && config.myHomeModules.fd.enable
          && config.myHomeModules.ripgrep.enable
        )
        (import ../../customPkgs {inherit pkgs;}).vf
      )
    ];
    sessionVariables = {
      TERMINAL = "wezterm";
      EDITOR = "nvim";
      VISUAL = "nvim";
      GIT_EDITOR = "nvim";
      MANPAGER = "nvim +Man!";
    };

    persistence."/persist/home/jmfv" = {
      directories = [
        "dev"
        "nixos-dot"
        "Downloads"
        "Documents"
        "Pictures"
        "Videos"
        # ".gnupg"
        ".ssh"
        # ".nixops"
        # ".local/share/keyrings"
        # ".local/share/direnv"
        # {
        #   directory = ".local/share/Steam";
        #   method = "symlink";
        # }
      ];
      allowOther = true;
    };
  };

  programs = {};

  services = {};
}
