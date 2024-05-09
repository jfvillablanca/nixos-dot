{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (inputs.nix-colors.lib-contrib {inherit pkgs;}) gtkThemeFromScheme;

  nixColorsTheme = {
    name = "${config.colorScheme.slug}";
    package = gtkThemeFromScheme {
      scheme = config.colorScheme;
    };
  };
in {
  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3";
      package = pkgs.adw-gtk3;
    };


  # NOTE: based off of this helpful comment
  # https://github.com/nix-community/home-manager/issues/5240#issuecomment-2068191397
  xdg.configFile = let
    nixColorsThemeDir = "${nixColorsTheme.package}/share/themes/${nixColorsTheme.name}";
  in {
    "gtk-3.0/gtk.css".source = "${nixColorsThemeDir}/gtk-3.0/gtk.css";
    "gtk-4.0/gtk.css".source = "${nixColorsThemeDir}/gtk-4.0/gtk.css";
  };

  home.packages = [nixColorsTheme.package];

  dconf.settings."org/gnome/desktop/interface".gtk-theme = lib.mkForce nixColorsTheme.name;
}
