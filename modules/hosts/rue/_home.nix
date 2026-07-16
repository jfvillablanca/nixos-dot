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
      nh
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
      # The flake clone lives here (repoPath = /home/jmfv/nixos-dot); persist
      # it so the clone and `nh os switch` survive the ephemeral-root wipe.
      "nixos-dot"
      ".ssh"
      # Sunshine pairing certs + config, so paired Moonlight clients survive
      # the ephemeral-root wipe (confirmed: reconnects without re-pairing).
      ".config/sunshine"
    ];
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
