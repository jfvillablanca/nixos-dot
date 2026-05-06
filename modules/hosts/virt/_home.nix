{
  pkgs,
  inputs,
  base16Scheme,
  ...
}: {
  imports =
    [
      inputs.nix-colors.homeManagerModules.default
    ]
    ++ (with inputs.self.modules.homeManager; [
      bash
      btop
      delta
      direnv
      eza
      fd
      fish
      flameshot
      fzf
      git
      neovim
      nh
      nom
      ripgrep
      starship
      tmux
      wezterm
      zoxide

      i3-stack
      wallpapers
      xdg
    ]);

  colorScheme = inputs.nix-colors.colorSchemes.${base16Scheme};

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
