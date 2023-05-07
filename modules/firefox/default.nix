{ pkgs, ... }:
let
  profile = "dev-edition-default";
  mozillaPath = ".mozilla/firefox/${profile}/chrome";
  addtlCss = [
    ./overrides/cleaner_extensions_menu.css
    ./overrides/hide_list-all-tabs_button.css
    ./overrides/no_search_engines_in_url_bar.css

    ./overrides/popout_bookmarks_bar_on_hover.css
    ./overrides/transparent_bookmarks_bar.css

    ./overrides/icons_in_main_menu.css
    ./overrides/privacy_blur_email_in_main_menu.css
    ./overrides/privacy_blur_email_in_sync_menu.css

    ./overrides/themes/acrylic_micaforeveryone.css
  ];
  cssFiles = builtins.listToAttrs (builtins.map
    (path: {
      name = mozillaPath + "/" + builtins.baseNameOf path;
      value = { source = path; };
    })
    addtlCss);
in
{
  home.file = {
    "${mozillaPath}/image" = {
      source = ./overrides/image;
      recursive = true;
    };
  } // cssFiles;

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-devedition; 
    profiles = {
      "${profile}" = {
        isDefault = true;
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "ui.systemUsesDarkTheme" = 1;
          "privacy.userContext.enabled" = true;
          "privacy.userContext.extension" = "@contain-facebook";
          "privacy.userContext.newTabContainerOnLeftClick.enabled" = true;
          "privacy.userContext.ui.enabled" = true;
        };
        search = {
          default = "DuckDuckGo";
        };
        userChrome = builtins.readFile ./overrides/userChrome.css;
        userContent = builtins.readFile ./overrides/userContent.css;
      };
    };
  };
}
