{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.hyprland;

  # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
  workspaces = builtins.concatLists (builtins.genList (
      x: let
        ws = let
          c = (x + 1) / 10;
        in
          builtins.toString (x + 1 - (c * 10));
      in [
        "$mainMod, ${ws}, workspace, ${toString (x + 1)}"
        "$mainMod SHIFT, ${ws}, movetoworkspacesilent, ${toString (x + 1)}"
      ]
    )
    10);

  defaultTerminal = lib.getExe pkgs.alacritty;

  hyprlandStartup = pkgs.writeShellApplication {
    name = "hyprland-startup";
    text = ''
      ${lib.getExe pkgs.eww} open bar &
      ${defaultTerminal}
    '';
  };
in {
  imports = [
    inputs.hyprland.homeManagerModules.default
  ];

  options.myHomeModules.hyprland = {
    enable =
      lib.mkEnableOption "enables hyprland"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;

      settings = {
        "$mainMod" = "SUPER";
        "$fileManager" = "thunar";
        "$terminal" = "${defaultTerminal}";
        "$menu" = "wofi --show drun";

        "exec-once" = lib.getExe hyprlandStartup;

        monitor =
          map (
            m: let
              resolution = "${toString m.width}x${toString m.height}@${toString m.refreshRate}";
              position = "${toString m.x}x${toString m.y}";
            in "${m.name},${
              if m.enabled
              then "${resolution},${position},1"
              else "disable"
            }"
          )
          config.myHomeModules.window-manager.monitors;

        decoration = {
          shadow_offset = "0 5";
          "col.shadow" = "rgba(00000099)";
        };
        animations = {
          enabled = true;
          animation = [
            "border, 1, 2, default"
            "fade, 1, 4, default"
            "windows, 1, 3, default, popin 80%"
            "workspaces, 1, 2, default, slide"
          ];
        };

        master = {
          new_is_master = false;
        };

        windowrulev2 = [
          "suppressevent maximize, class:.*"
        ];

        bind =
          [
            "$mainMod, Return, exec, $terminal"
            "$mainMod, D, exec, $menu"

            # compositor commands
            "$mainMod SHIFT, Q, killactive"
            "$mainMod, F, fullscreen"
            "$mainMod, W, togglegroup"
            "$mainMod SHIFT, N, changegroupactive, f"
            "$mainMod SHIFT, P, changegroupactive, b"
            "$mainMod, Y, togglesplit,"
            "$mainMod SHIFT, F, togglefloating,"

            # move focus
            "$mainMod, left, movefocus, l"
            "$mainMod, right, movefocus, r"
            "$mainMod, up, movefocus, u"
            "$mainMod, down, movefocus, d"

            # special workspace
            # "$mainMod, S, togglespecialworkspace, magic"
            # "$mainMod SHIFT, S, movetoworkspace, special:magic"
            # "$mainMod SHIFT, grave, movetoworkspace, special"
            # "$mainMod, grave, togglespecialworkspace, eDP-1"

            # cycle workspaces
            # "$mainMod, bracketleft, workspace, m-1"
            # "$mainMod, bracketright, workspace, m+1"

            # cycle monitors
            # "$mainMod SHIFT, bracketleft, focusmonitor, l"
            # "$mainMod SHIFT, bracketright, focusmonitor, r"

            # send focused workspace to left/right monitors
            # "$mainMod SHIFT ALT, bracketleft, movecurrentworkspacetomonitor, l"
            # "$mainMod SHIFT ALT, bracketright, movecurrentworkspacetomonitor, r"
          ]
          ++ workspaces;

        bindm = [
          # mouse movements
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
          "$mainMod ALT, mouse:272, resizewindow"
        ];
      };

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
