{ ... }:
{
  programs = {
    zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      enableSyntaxHighlighting = true;
      shellAliases = {
        ".." = "cd ..";
        "use" = "nix-shell -p";
        "usep" = "nix-shell --pure -p";
        "review" = " nix-shell -p nixpkgs-review --run 'nixpkgs-review rev HEAD'";
        "nixs" = ''
          manix "" | grep '^# ' | sed 's/^# \(.*\) (.*/\1/;s/ (.*//;s/^# //' | fzf --preview="manix '{}'" | xargs manix
        '';
      };
    };
  };
}
