{
  inputs,
  pkgs,
  config,
  ...
}: let
  inherit (inputs.nix-colors.lib-contrib {inherit pkgs;}) gtkThemeFromScheme;
in {
  qt = {
    enable = true;
    platformTheme = "gtk";
  };

  gtk = {
    enable = true;
    theme = {
      name = "${config.colorScheme.slug}";
      package = gtkThemeFromScheme {
        scheme = config.colorScheme;
      };
    };
  };
}
