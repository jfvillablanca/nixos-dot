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
                "nixs" = ''
                manix "" | grep '^# ' | sed 's/^# \(.*\) (.*/\1/;s/ (.*//;s/^# //' | fzf --preview="manix '{}'" | xargs manix
                '';
            };
        };
    };
}
