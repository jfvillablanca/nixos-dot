{
  flake.modules.homeManager.aerospace = {lib, ...}: let
    workspaceKeys =
      map toString (lib.range 1 9)
      ++ lib.stringToCharacters "abcdefgimnopqrstuvwxyz";

    workspaceBindings =
      lib.concatMap (
        k: let
          ws = lib.toUpper k;
        in [
          (lib.nameValuePair "ctrl-alt-${k}" "workspace ${ws}")
          (lib.nameValuePair "ctrl-alt-shift-${k}" "move-node-to-workspace ${ws}")
        ]
      )
      workspaceKeys;

    mainBindings = [
      (lib.nameValuePair "ctrl-alt-slash" "layout tiles horizontal vertical")
      (lib.nameValuePair "ctrl-alt-comma" "layout accordion horizontal vertical")

      (lib.nameValuePair "ctrl-alt-left" "focus left")
      (lib.nameValuePair "ctrl-alt-down" "focus down")
      (lib.nameValuePair "ctrl-alt-up" "focus up")
      (lib.nameValuePair "ctrl-alt-right" "focus right")

      (lib.nameValuePair "ctrl-alt-shift-left" "move left")
      (lib.nameValuePair "ctrl-alt-shift-down" "move down")
      (lib.nameValuePair "ctrl-alt-shift-up" "move up")
      (lib.nameValuePair "ctrl-alt-shift-right" "move right")

      (lib.nameValuePair "ctrl-alt-minus" "resize smart -50")
      (lib.nameValuePair "ctrl-alt-equal" "resize smart +50")

      (lib.nameValuePair "ctrl-alt-tab" "workspace-back-and-forth")
      (lib.nameValuePair "ctrl-alt-shift-tab" "move-workspace-to-monitor --wrap-around next")

      (lib.nameValuePair "ctrl-alt-shift-semicolon" "mode service")
    ];
  in {
    config = {
      programs.aerospace = {
        enable = true;
        launchd.enable = true;
        settings = {
          "config-version" = 2;
          "after-startup-command" = [];
          "enable-normalization-flatten-containers" = true;
          "enable-normalization-opposite-orientation-for-nested-containers" = true;
          "accordion-padding" = 30;
          "default-root-container-layout" = "tiles";
          "default-root-container-orientation" = "auto";
          "on-focused-monitor-changed" = ["move-mouse monitor-lazy-center"];
          "automatically-unhide-macos-hidden-apps" = false;
          "on-mode-changed" = [];
          "persistent-workspaces" = map lib.toUpper workspaceKeys;

          "key-mapping".preset = "qwerty";

          gaps = {
            inner.horizontal = 0;
            inner.vertical = 0;
            outer.left = 5;
            outer.bottom = 5;
            outer.top = 5;
            outer.right = 5;
          };

          mode.main.binding = builtins.listToAttrs (mainBindings ++ workspaceBindings);

          mode.service.binding = {
            esc = ["reload-config" "mode main"];
            r = ["flatten-workspace-tree" "mode main"];
            f = ["layout floating tiling" "mode main"];
            backspace = ["close-all-windows-but-current" "mode main"];
            "ctrl-alt-shift-left" = ["join-with left" "mode main"];
            "ctrl-alt-shift-down" = ["join-with down" "mode main"];
            "ctrl-alt-shift-up" = ["join-with up" "mode main"];
            "ctrl-alt-shift-right" = ["join-with right" "mode main"];
          };
        };
      };
    };
  };
}
