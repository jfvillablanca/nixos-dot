{ ... }:
{
    xdg.configFile."zellij" = {
        source = ./zellij;
        recursive = true;
    };

    programs = {
        zellij = {
            enable = true;
        };
    };
}
