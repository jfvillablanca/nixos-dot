_:
let
  profile = "hello";
  mozillaPath = ".mozilla/firefox/${profile}/chrome";
  addtlCss = [
    ./overrides/remove_folder_icons_from_bookmarks.css
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
