{ pkgs, ... }:
{
  programs = {
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      initExtra = ''
        export PATH="$PATH:$HOME/.npm-global/bin"         # (temporary) for non-declarative npm global installs
        function nvim_fzf() {
            local fname
            fname=$(fd                                    \
                    --type f                              \
                    --hidden                              \
                    --exclude node_modules                \
                    --exclude .git                        \
                    | fzf                                 \
                    --multi                               \
                    --preview='bat                        \
                              --color=always              \
                              --theme=catppuccin-mocha    \
                              --style=numbers {}          \
            ') || return
            nvim "$fname"
        }
        function lfcd () {
            # `command` is needed in case `lfcd` is aliased to `lf`
            cd "$(command lf -print-last-dir "$@")" || exit
        }
      '';
      shellAliases = {
        ".." = "cd ..";

        "vf" = "nvim_fzf";

        # Trashy
        "restore" = "trash list | fzf --multi | awk '{$1=$1;print}' | rev | cut -d ' ' -f1 | rev | xargs trash restore --match=exact --force";
        "empty" = "trash list | fzf --multi | awk '{$1=$1;print}' | rev | cut -d ' ' -f1 | rev | xargs trash empty --match=exact --force";

        # lf
        "lf" = "lfcd";

        # Nix-specific
        "use" = "nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/master.tar.gz -p";
        "usep" = "nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/master.tar.gz --pure -p";
        "review" = " nix-shell -p nixpkgs-review --run 'nixpkgs-review rev HEAD'";
        "nixmeta" = "nix-shell -p nix-info --run 'nix-info -m'";
        "nixs" = ''
          manix "" | grep '^# ' | sed 's/^# \(.*\) (.*/\1/;s/ (.*//;s/^# //' | fzf --preview="manix '{}'" | xargs manix
        '';
      };
    };
  };
}
