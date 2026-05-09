{
  # pkgs,
  writeShellApplication,
}:
writeShellApplication {
  name = "vfx";
  # NOTE: same approach as `vf` — runtimeInputs is intentionally not closed
  # over so we pick up the bat / fd / fzf already on $PATH via home.packages
  # (and `vimx`, the wrapped `.#nvim-experimental-cimmerian`, installed
  # alongside this package on cimmerian).
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
    vimx "$fname"
  '';
}
