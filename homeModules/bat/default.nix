{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.bat;
  themeType = lib.types.enum [
    "catppuccin-frappe"
    "catppuccin-latte"
    "catppuccin-mocha"
    "catppuccin-macchiato"
    "dracula"
    "everblush"
  ];
in {
  options.myHomeModules.bat = {
    enable =
      lib.mkEnableOption "enables bat"
      // {
        default = true;
      };
    theme = lib.mkOption {
      type = themeType;
      default = "catppuccin-mocha";
    };
  };
  config = lib.mkIf cfg.enable {
    programs.bat = {
      enable = true;
      config = {
        inherit (cfg) theme;
      };
      themes = {
        dracula = {
          src = pkgs.fetchFromGitHub {
            owner = "dracula";
            repo = "sublime";
            rev = "456d3289827964a6cb503a3b0a6448f4326f291b";
            sha256 = "sha256-8mCovVSrBjtFi5q+XQdqAaqOt3Q+Fo29eIDwECOViro=";
          };
          file = "Dracula.tmTheme";
        };

        everblush = {
          src = pkgs.fetchFromGitHub {
            owner = "Everblush";
            repo = "bat";
            rev = "0e982b52373167a895f88756e071d3dfff07307f";
            sha256 = "sha256-DuHV2IjJq1F/AX/QIarJCDdzycayqPbUHK9hCCvKOcM=";
          };
          file = "Everblush.tmTheme";
        };

        catppuccin-frappe = {
          src =
            pkgs.fetchFromGitHub
            {
              owner = "catppuccin";
              repo = "bat";
              rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
              sha256 = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
            };
          file = "Catppuccin-frappe.tmTheme";
        };

        catppuccin-latte = {
          src =
            pkgs.fetchFromGitHub
            {
              owner = "catppuccin";
              repo = "bat";
              rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
              sha256 = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
            };
          file = "Catppuccin-latte.tmTheme";
        };

        catppuccin-macchiato = {
          src =
            pkgs.fetchFromGitHub
            {
              owner = "catppuccin";
              repo = "bat";
              rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
              sha256 = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
            };
          file = "Catppuccin-macchiato.tmTheme";
        };

        catppuccin-mocha = {
          src =
            pkgs.fetchFromGitHub
            {
              owner = "catppuccin";
              repo = "bat";
              rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
              sha256 = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
            };
          file = "Catppuccin-mocha.tmTheme";
        };
      };
      extraPackages = with pkgs.bat-extras; [
        batgrep
      ];
    };
  };
}
