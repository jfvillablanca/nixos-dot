{ ... }:
{
  xdg.configFile."zellij" = {
    source = ./configs;
    recursive = true;
  };

  programs = {
    zellij = {
      enable = true;
    };
  };
}
