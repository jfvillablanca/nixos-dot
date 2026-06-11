{
  flake.modules.homeManager.aerospace = {
    lib,
    pkgs,
    config,
    ...
  }: let
    workspaceKeys =
      map toString (lib.range 1 9);

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

    # Dynamic workspace persistence. AeroSpace has no native session restore,
    # so we roll our own on the CLI: on-focus-changed snapshots the live
    # window->workspace map, and a login agent replays it as macOS reopens
    # windows (otherwise they all pile onto workspace 1). Match is by
    # bundle-id + title (window-ids are regenerated across reboot), falling
    # back to the app's first-seen workspace.
    layoutFormat = "%{window-id} %{app-bundle-id} %{workspace} %{window-title}";
    stateExpr = "\${XDG_STATE_HOME:-$HOME/.local/state}/aerospace";

    layoutSave = pkgs.writeShellApplication {
      name = "aerospace-layout-save";
      runtimeInputs = [config.programs.aerospace.package pkgs.jq pkgs.coreutils];
      text = ''
        state="${stateExpr}"
        # Don't capture the mid-restore pile-up over the good snapshot.
        if [ -e "$state/restore.lock" ]; then exit 0; fi
        mkdir -p "$state"
        tmp="$(mktemp "$state/layout.XXXXXX")"
        if aerospace list-windows --all --format ${lib.escapeShellArg layoutFormat} --json >"$tmp" 2>/dev/null; then
          mv -f "$tmp" "$state/layout.json"
        else
          rm -f "$tmp"
        fi
      '';
    };

    layoutRestore = pkgs.writeShellApplication {
      name = "aerospace-layout-restore";
      runtimeInputs = [config.programs.aerospace.package pkgs.jq pkgs.coreutils];
      text = ''
        state="${stateExpr}"
        layout="$state/layout.json"
        if [ ! -f "$layout" ]; then exit 0; fi
        mkdir -p "$state"

        # Lock out the saver while we replay, release on any exit.
        : >"$state/restore.lock"
        trap 'rm -f "$state/restore.lock"' EXIT

        placed=" "
        deadline=$(( $(date +%s) + 30 ))
        # macOS reopens windows over several seconds; poll, place each window
        # exactly once as it appears, then stop fighting the user.
        while [ "$(date +%s)" -lt "$deadline" ]; do
          current="$(aerospace list-windows --all --format ${lib.escapeShellArg layoutFormat} --json 2>/dev/null)" || { sleep 1; continue; }
          moves="$(jq -rn --argjson saved "$(cat "$layout")" --argjson cur "$current" '
            $cur[] as $w
            | ([ $saved[] | select(.["app-bundle-id"] == $w["app-bundle-id"] and .["window-title"] == $w["window-title"]) | .workspace ][0]) as $exact
            | ([ $saved[] | select(.["app-bundle-id"] == $w["app-bundle-id"]) | .workspace ][0]) as $byApp
            | ($exact // $byApp) as $target
            | select($target != null and $target != $w.workspace)
            | "\($w["window-id"]) \($target)"
          ')" || { sleep 1; continue; }
          while read -r wid ws; do
            if [ -z "$wid" ]; then continue; fi
            case "$placed" in *" $wid "*) continue ;; esac
            aerospace move-node-to-workspace --window-id "$wid" "$ws" >/dev/null 2>&1 || true
            placed="$placed$wid "
          done <<< "$moves"
          sleep 1
        done
      '';
    };
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
          "on-focus-changed" = ["exec-and-forget ${layoutSave}/bin/aerospace-layout-save"];
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

      # Replay the saved layout at login. Runs once (no KeepAlive); the
      # script self-limits to ~30s of polling. On a normal `darwin switch`
      # the live layout already matches the snapshot, so it no-ops.
      launchd.agents.aerospace-layout-restore = {
        enable = true;
        config = {
          ProgramArguments = ["${layoutRestore}/bin/aerospace-layout-restore"];
          RunAtLoad = true;
          StandardOutPath = "/tmp/aerospace-layout-restore.out.log";
          StandardErrorPath = "/tmp/aerospace-layout-restore.err.log";
        };
      };

      home.packages = [layoutSave layoutRestore];
    };
  };
}
