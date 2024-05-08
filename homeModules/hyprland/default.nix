{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.hyprland;

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

  defaultTerminal = lib.getExe pkgs.wezterm;

  hyprlandStartup = pkgs.writeShellApplication {
    name = "hyprland-startup";
    text = ''
      ${lib.getExe pkgs.waybar} &
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
    home.packages = [
      inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
    ];

    wayland.windowManager.hyprland = {
      enable = true;

      settings = {
        "$mainMod" = "SUPER";
        "$fileManager" = "thunar";
        "$terminal" = "${defaultTerminal}";
        "$menu" = "${lib.getExe pkgs.wofi} --show drun";

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

        general = {
          layout = "master";
          no_cursor_warps = true;
          resize_on_border = true;

          gaps_in = 4;
          gaps_out = 8;
          border_size = 2;
          "col.active_border" = "0xff${config.colorScheme.palette.base0E}";
          "col.inactive_border" = "0xff${config.colorScheme.palette.base0D}";
        };

        group = {
          "col.border_active" = "0xff${config.colorScheme.palette.base0E}";
          "col.border_inactive" = "0xff${config.colorScheme.palette.base0D}";
          "col.border_locked_active" = "0xff${config.colorScheme.palette.base08}";
          "col.border_locked_inactive" = "0xff${config.colorScheme.palette.base09}";
          groupbar = {
            height = 3;
            render_titles = false;
            "col.active" = "0xbb${config.colorScheme.palette.base0E}";
            "col.inactive" = "0xbb${config.colorScheme.palette.base0D}";
            "col.locked_active" = "0xbb${config.colorScheme.palette.base08}";
            "col.locked_inactive" = "0xbb${config.colorScheme.palette.base09}";
          };
        };

        decoration = {
          shadow_offset = "0 5";
          "col.shadow" = "rgba(00000099)";

          rounding = 5;
          active_opacity = 1.0;
          inactive_opacity = 0.9;
        };

        misc = {
          disable_splash_rendering = true;
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
          "bordercolor rgb(${config.colorScheme.palette.base08}) rgb(${config.colorScheme.palette.base0B}),fullscreen:1"
          "bordersize 4,fullscreen:1"
        ];

        bind =
          [
            "$mainMod, Return, exec, $terminal"
            "$mainMod, D, exec, $menu"
            # compositor commands
            "$mainMod SHIFT, Q, killactive"
            "$mainMod, F, fullscreen, 1"
            "$mainMod, W, togglegroup"
            "$mainMod, Y, togglesplit,"
            "$mainMod SHIFT, F, togglefloating,"

            "$mainMod, left, movefocus, l"
            "$mainMod, right, movefocus, r"
            "$mainMod, up, movefocus, u"
            "$mainMod, down, movefocus, d"

            "$mainMod ALT, left, changegroupactive, b"
            "$mainMod ALT, right, changegroupactive, f"
            "$mainMod SHIFT, left, movewindoworgroup, l"
            "$mainMod SHIFT, right, movewindoworgroup, r"
            "$mainMod SHIFT, up, movewindoworgroup, u"
            "$mainMod SHIFT, down, movewindoworgroup, d"

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

        bindle = [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", PRINT, exec, grimblast copy area"
          "SHIFT, PRINT, exec, grimblast save area ${config.xdg.userDirs.pictures}/Screenshot-$(date +%F_%T).png\n"
        ];

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
