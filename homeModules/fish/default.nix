{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.fish;
in {
  options.myHomeModules.fish = {
    enable =
      lib.mkEnableOption "enables fish"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      fish = {
        enable = true;
        functions = {
          # subtly rewritten to match fish's syntax
          vf = ''
            set fname (fd                                 \
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
            nvim $fname
          '';

          lf = ''
            # `command` is needed in case `lfcd` is aliased to `lf`
            cd (command lf -print-last-dir $argv) || exit
          '';
        };
        shellAliases = {
          ".." = "cd ..";

          # Trashy
          "restore" = "trash list | fzf --multi | awk '{$1=$1;print}' | rev | cut -d ' ' -f1 | rev | xargs trash restore --match=exact --force";
          "empty" = "trash list | fzf --multi | awk '{$1=$1;print}' | rev | cut -d ' ' -f1 | rev | xargs trash empty --match=exact --force";

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
  };
}
