let
  # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
  workspaces = builtins.concatLists (builtins.genList (
      x: let
        ws = let
          c = (x + 1) / 10;
        in
          builtins.toString (x + 1 - (c * 10));
      in [
        "$mainMod, ${ws}, workspace, ${toString (x + 1)}"
        "$mainMod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
      ]
    )
    10);
in {
  wayland.windowManager.hyprland.settings = {
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
}
