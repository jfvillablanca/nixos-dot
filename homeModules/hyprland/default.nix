{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.hyprland;
in {
  imports = [
    inputs.hyprland.homeManagerModules.default

    ./settings.nix
    ./binds.nix
    ./rules.nix
  ];

  options.myHomeModules.hyprland = {
    enable =
      lib.mkEnableOption "enables hyprland"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    # Wayland-specific packages
    home.packages = with pkgs; [
      wl-clipboard
    ];

    # Hyprland config
    wayland.windowManager.hyprland = {
      enable = true;

      systemd = {
        variables = ["--all"];
        extraCommands = [
          "systemctl --user stop graphical-session.target"
          "systemctl --user start hyprland-session.target"
        ];
      };
    };
  };
}
