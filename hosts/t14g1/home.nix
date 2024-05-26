{
  config,
  inputs,
  lib,
  pkgs,
  user,
  base16Scheme,
  ...
}: {
  imports = [
    inputs.nix-colors.homeManagerModules.default
    # inputs.walker.homeManagerModules.walker
    inputs.impermanence.nixosModules.home-manager.impermanence

    ../../homeModules/system/xdg.nix
    ../../homeModules/system/gtk.nix

    ../../homeModules/system/wallpapers
  ];

  colorScheme = inputs.nix-colors.colorSchemes.${base16Scheme};

  myHomeModules = {
    window-manager = {
      enable = true;
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
        # {
        #   name = "HDMI-1";
        #   # For Hyprland, `hyperctl monitors` lists it as "HDMI-A-1"
        #   # name = "HDMI-A-1";
        #   width = 1920;
        #   height = 1080;
        #   x = 1920;
        #   y = 0;
        # }
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
    packages = with pkgs; [
      # Terminal
      tldr # Lazy man's help/man page
      nixpkgs-review # For reviewing PRs to nixpkgs repository
      trashy # Trash in cli
      killall # Kill processes
      ncdu # NCurses Disk Usage
      unzip # Zip utility
      zip # Zip utility
      lazydocker # Docker and Docker compose management utility

      # Browser
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
      xfce.thunar # Xfce file manager
      xfce.thunar-volman # Removable media Thunar extension

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

    persistence."/persist/home/${user}" = {
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
        ".local/share/direnv"
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
