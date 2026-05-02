{
  # pkgs,
  writeShellApplication,
}:
writeShellApplication {
  name = "vf";
  # NOTE:
  # Uncomment `runtimeInputs` if you want the package to be reproducible
  # This is deliberately commented out in order to use the
  # "bat, fd, and fzf, neovim" that's already a part of my home.packages
  # (the configurations are managed by home-manager)
  # If you use the closured `runtimeInputs`, it won't have access to
  # configs in $XDG_CONFIG_HOME
  # runtimeInputs = with pkgs; [
  #   bat
  #   fd
  #   fzf
  #   neovim
  # ];
  text = ''
    fname=$(fd                                \
        --type f                              \
        --hidden                              \
        --exclude node_modules                \
        --exclude .git                        \
        | fzf                                 \
        --multi                               \
        --preview='bat                        \
                  --color=always              \
                  --style=numbers {}          \
        ')
    nvim "$fname"
  '';
}
