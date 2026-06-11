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
      alacritty
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
      kitty
      moonlight
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
          name = "HDMI-1";
          # For Hyprland, `hyperctl monitors` lists it as "HDMI-A-1"
          # name = "HDMI-A-1";
          isPrimary = true;
          width = 1920;
          height = 1080;
          x = 0;
          y = 0;
          rotate = "left";
          fingerprint = "00ffffffffffff003103ffff000000001920010380301a782aeed5a3544c99230f5054bfef80714f81c0814081809500a9c0b300d1c0023a801871382d40582c4500df041100001e000000fd00304c345414000a202020202020000000fc004d4c2d32320a20202020202020000000ff0030303030303030303030303030015f020329f14b90010203041112131f051423091f078301000067030c001000b83c681a00000101304bed8e4480a070382d40582c4500df041100001c662156aa51001e30468f3300df041100001c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000034";
        }
        {
          name = "DP-1";
          width = 1920;
          height = 1080;
          x = 1080;
          y = 0;
          fingerprint = "00ffffffffffff003669a94b0000000020210104b5351d783af705a3564d99260d5054bfcf00714f81c0818081009500b300d1c00101023a801871382d40582c450012222100001e000000fc004d5349204d50323431320a2020000000fd0030645d5d21010a202020202020000000ff004241394834323338303337383601e702031a3448900102030412131f83010000681a00000101306400484d80a0703827403020350012222100001aeb5a80a0703827403020350012222100001e6e0ad0b02040142018403a0012222100001c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000038";
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
    packages = with pkgs; [
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

      # GUI
      thunar # Xfce file manager
      thunar-volman # Removable media Thunar extension
      libreoffice-qt
      proton-vpn

      pkgs.vf
      pkgs.vfx
    ];
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
