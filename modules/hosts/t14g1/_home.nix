{
  inputs,
  pkgs,
  base16Scheme,
  ...
}: {
  imports =
    [
      inputs.nix-colors.homeManagerModules.default
      # inputs.walker.homeManagerModules.walker
    ]
    ++ (with inputs.self.modules.homeManager; [
      bash
      bat
      btop
      claudeCode
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
      neovim
      nh
      nom
      ripgrep
      starship
      tmux
      wezterm
      kitty
      yazi
      zellij
      zoxide
      zsh

      moonlight

      hyprland-stack
      wallpapers
      xdg
    ]);

  programs.moonlight.extraSettings = {
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
    claudeCode.enable = true;
    window-manager = {
      monitors = [
        {
          name = "eDP-1";
          isPrimary = true;
          width = 1920;
          height = 1080;
          x = 0;
          # x = 1920;
          y = 0;
        }
        # {
        #   # name = "HDMI-1";
        #   # For Hyprland, `hyperctl monitors` lists it as "HDMI-A-1"
        #   name = "HDMI-A-1";
        #   width = 1920;
        #   height = 1080;
        #   # x = 1920;
        #   x = 0;
        #   y = 0;
        # }
      ];
    };
  };

  stylix = {
    targets = {
    };
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
      nix-init
      libreoffice-qt
      devenv

      # Browser
      # Alternate browser for running web apps that are "unoptimized" in Firefox (or can't play with Firefox's hardened security policies)
      google-chrome

      # Misc
      fastfetch # System lookup
      musescore # Music notation and composition
      discord # Communications

      # Utils
      pavucontrol # Volume control UI
      pamixer # PipeWire CLI tool
      vlc # Video player
      file-roller # File archiving
      eog # GUI image viewer
      onboard # On-screen keyboard
      zathura # PDF Viewer

      # GUI
      thunar # Xfce file manager
      thunar-volman # Removable media Thunar extension
      zoom-us
      vscode
      virt-viewer

      pkgs.vf
    ];
    sessionVariables = {
      TERMINAL = "wezterm";
      EDITOR = "nvim";
      VISUAL = "nvim";
      GIT_EDITOR = "nvim";
      MANPAGER = "nvim +Man!";
    };
  };

  myHomeModules.persistence = {
    enable = true;
    # impermanence 2026-01 appends the home dir automatically; give the
    # prefix only ("/persist" -> stored at /persist/home/<user>, unchanged).
    root = "/persist";
    directories = [
      "dev"
      "nixos-dot"
      "Downloads"
      "Documents"
      "Pictures"
      "Videos"
      # ".gnupg"
      ".ssh"
      ".config/gh"
      # ".nixops"
      # ".local/share/keyrings"
      ".local/share/direnv"
      ".local/share/fish"
      ".local/share/zoxide"
      ".local/state/nvim"
      ".tmux/resurrect"
      # firefox adopted the XDG configPath (~/.config/mozilla/firefox) in
      # 26.05+; persist the new path so the profile survives the wipe. The
      # on-disk profile is migrated from .mozilla/firefox out of band.
      ".config/mozilla/firefox"

      # the idiot apps that use the .config directory
      # to store state
      ".config/google-chrome"
      ".config/discord"
      ".config/Moonlight Game Streaming Project"
      # {
      #   directory = ".local/share/Steam";
      #   method = "symlink";
      # }
    ];
    files = [];
  };

  programs = {};

  services = {};
}
