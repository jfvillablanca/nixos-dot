{ ... }:
{
    programs = {
        exa = {
            enable = true;
            git = true;
            icons = true;
            extraOptions = [
                "--group-directories-first"
            ];
            enableAliases = true;
        };
    };
}
