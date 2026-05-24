{
  inputs,
  pkgs,
  pkgs-master,
  base16Scheme,
  ...
}: {
  imports =
    [
      inputs.nix-colors.homeManagerModules.default
      # inputs.walker.homeManagerModules.walker
    ]
    ++ (with inputs.self.modules.homeManager; [
      alacritty
      bash
      bat
      btop
      delta
      direnv
      eza
      fd
      firefox
      fish
      flameshot
      fzf
      gh
      git
      gitui
      kitty
      moonlight-qt
      neovim
      nh
      nom
      pet
      ripgrep
      starship
      tmux
      wezterm
      yazi
      zathura
      zoxide
      zsh

      i3-stack
      wallpapers
      xdg
    ]);

  programs.moonlight-qt.extraSettings = {
    General = {
      width = 1920;
      height = 1080;
      fps = 60;
      bitrate = 50000;
      videocfg = 2; # 0=auto, 1=H.264, 2=HEVC, 4=AV1
    };
  };

  colorScheme = inputs.nix-colors.colorSchemes.${base16Scheme};

  myHomeModules = {
    window-manager = {
      monitors = [
        {
          name = "HDMI-1";
          # For Hyprland, `hyperctl monitors` lists it as "HDMI-A-1"
          # name = "HDMI-A-1";
          isPrimary = true;
          width = 1920;
          height = 1080;
          x = 0;
          y = 0;
          rotate = "left";
        }
        {
          name = "DP-1";
          width = 1920;
          height = 1080;
          x = 1080;
          y = 0;
        }
      ];
      statusBarMonitor = "DP-1";
    };
  };

  stylix = {
    targets = {
    };
  };

  home = {
    packages = with pkgs;
      [
        # Terminal
        tldr # Lazy man's help/man page
        nixpkgs-review # For reviewing PRs to nixpkgs repository
        cachix # Nix binary cache hosting
        trashy # Trash in cli
        killall # Kill processes
        ncdu # NCurses Disk Usage
        unzip # Zip utility
        zip # Zip utility
        devenv

        inputs.self.packages.x86_64-linux.vimx

        # Browser
        # Alternate browser for running web apps that are "unoptimized" in Firefox (or can't play with Firefox's hardened security policies)
        google-chrome

        # Misc
        neofetch # System lookup
        musescore # Music notation and composition
        discord # Communications

        # Utils
        pavucontrol # Volume control UI
        pamixer # PipeWire CLI tool
        vlc # Video player
        file-roller # File archiving
        eog # GUI image viewer
        onboard # On-screen keyboard

        # GUI
        xfce.thunar # Xfce file manager
        xfce.thunar-volman # Removable media Thunar extension
        libreoffice-qt
        protonvpn-gui

        pkgs.vf
        pkgs.vfx
      ]
      ++ (with pkgs-master; [
        claude-code
      ]);
    sessionVariables = {
      TERMINAL = "wezterm";
      EDITOR = "nvim";
      VISUAL = "nvim";
      GIT_EDITOR = "nvim";
      MANPAGER = "nvim +Man!";
    };
  };

  programs = {
    # NOTE:
    # seems to be enabled by default for stateVersion < 23.05
    # causes an infinite loop error upon evaluation thus this is manually disabled
    # https://home-manager-options.extranix.com/?query=swaylock&release=release-24.05
  };

  services = {};
}
