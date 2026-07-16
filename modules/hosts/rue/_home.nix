{
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
      bat
      btop
      direnv
      eza
      fd
      fish
      fzf
      git
      kitty
      neovim
      ripgrep
      starship
      tmux
      yazi
      zoxide
      zsh
    ]);

  colorScheme = inputs.nix-colors.colorSchemes.${base16Scheme};

  myHomeModules.persistence = {
    enable = true;
    # impermanence appends the home dir automatically; give the prefix only
    # ("/persist" -> /persist/home/<user>).
    root = "/persist";
    directories = [
      ".ssh"
      # Sunshine pairing certs + config: persist so paired Moonlight clients
      # survive the ephemeral-root wipe. VERIFY this is the real dir first.
      ".config/sunshine"
    ];
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
