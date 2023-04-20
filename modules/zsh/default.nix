{ ... }:
{
  programs = {
    zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      enableSyntaxHighlighting = true;
      initExtra = ''
        function nvim_fzf() {
            local fname
            fname=$(fd --hidden --type f | fzf --preview='bat --color=always --theme=Dracula --style=numbers {}') || return
            nvim "$fname"
        }
      '';
      shellAliases = {
        ".." = "cd ..";

        "vf" = "nvim_fzf";

        # Nix-specific
        "use" = "nix-shell -p";
        "usep" = "nix-shell --pure -p";
        "review" = " nix-shell -p nixpkgs-review --run 'nixpkgs-review rev HEAD'";
        "nixmeta" = "nix-shell -p nix-info --run 'nix-info -m'";
        "nixs" = ''
          manix "" | grep '^# ' | sed 's/^# \(.*\) (.*/\1/;s/ (.*//;s/^# //' | fzf --preview="manix '{}'" | xargs manix
        '';
      };
    };
  };
}
