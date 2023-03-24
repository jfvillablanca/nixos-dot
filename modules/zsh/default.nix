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
                "mkdir" = "mkdir -r";
                "use" = "nix-shell -p";
                "nixs" = ''
                manix "" | grep '^# ' | sed 's/^# \(.*\) (.*/\1/;s/ (.*//;s/^# //' | fzf --preview="manix '{}'" | xargs manix
                '';
            };
        };
    };
}
