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
            };
        };
    };
}
