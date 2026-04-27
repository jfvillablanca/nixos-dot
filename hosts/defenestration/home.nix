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
    inputs.impermanence.nixosModules.home-manager.impermanence
  ];

  colorScheme = inputs.nix-colors.colorSchemes.${base16Scheme};

  myHomeModules = {
    git.enable = true;
    delta.enable = true;
    gh.enable = true;
    neovim.enable = true;

    alacritty.enable = false;
    wezterm.enable = false;

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
    zellij.enable = false;

    bash.enable = true;
    fish.enable = true;
    zsh.enable = true;

    firefox.enable = true;
  };

  stylix = {
    # targets = {
    #   waybar.enable = false;
    # };
  };

  home = {
    packages = with pkgs; [
      # Terminal
      tldr # Lazy man's help/man page
      killall # Kill processes
      ncdu # NCurses Disk Usage
      unzip # Zip utility
      zip # Zip utility

      # Browser
      # Alternate browser for running web apps that are "unoptimized" in Firefox (or can't play with Firefox's hardened security policies)
      google-chrome

      # Misc
      neofetch # System lookup
      discord # Communications

      (
        lib.mkIf (
          config.myHomeModules.neovim.enable
          && config.myHomeModules.bat.enable
          && config.myHomeModules.fd.enable
          && config.myHomeModules.ripgrep.enable
        )
        (import ../../customPkgs {inherit pkgs;}).vf
      )
      (import ../../customPkgs {inherit pkgs;}).use
    ];
    sessionVariables = {
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
        ".config/gh"
        # ".nixops"
        # ".local/share/keyrings"
        ".local/share/direnv"
        ".local/share/fish"
        ".local/share/zoxide"
        ".local/state/nvim"
        ".tmux/resurrect"
        ".mozilla/firefox"

        # the idiot apps that use the .config directory
        # to store state
        ".config/google-chrome"
        ".config/discord"
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
