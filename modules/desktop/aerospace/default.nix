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
    # windows (otherwise they pile onto the focused workspace). Placement is
    # count-based per app: each app's snapshot workspaces are slots, filled by
    # the present windows (exact title first, then by count) -- robust to the
    # title drift that breaks 1:1 matching across reboot. Apps with no native
    # window restoration (terminals) under-restore; for the respawnApps
    # allowlist we `open -n` the missing windows so they exist to be placed.
    layoutFormat = "%{window-id} %{app-bundle-id} %{workspace} %{window-title}";
    stateExpr = "\${XDG_STATE_HOME:-$HOME/.local/state}/aerospace";
    respawnAppsJson = builtins.toJSON config.myHomeModules.aerospace.respawnApps;

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

        respawn='${respawnAppsJson}'

        log() { echo "[$(date '+%H:%M:%S')] $*"; }
        log "=== restore run $(date '+%Y-%m-%d %H:%M:%S') ==="
        log "snapshot: $(jq -r 'length' "$layout" 2>/dev/null || echo '?') windows; respawn=$respawn"
        jq -r '.[] | "  saved: \(.["app-bundle-id"]) ws\(.workspace) [\(.["window-title"])]"' "$layout" 2>/dev/null || true

        # Lock out the saver while we replay, release on any exit.
        : >"$state/restore.lock"
        trap 'rm -f "$state/restore.lock"; log "=== restore done ==="' EXIT

        placed='{}'           # window-id -> assigned workspace (grows across polls)
        declare -A spawned    # bundle-id -> 1 once its deficit has been opened
        declare -A prevcount  # bundle-id -> present count at the previous poll
        declare -A stable     # bundle-id -> consecutive polls with an unchanged count
        settle=3

        deadline=$(( $(date +%s) + 30 ))
        iter=0
        # macOS reopens windows over several seconds; poll, placing each window
        # into its app's free slots as it appears, and re-spawning the rest.
        while [ "$(date +%s)" -lt "$deadline" ]; do
          iter=$(( iter + 1 ))
          current="$(aerospace list-windows --all --format ${lib.escapeShellArg layoutFormat} --json 2>/dev/null)" || { sleep 1; continue; }
          log "poll #$iter: $(printf '%s' "$current" | jq 'length' 2>/dev/null || echo 0) windows present"

          # Per app, treat the snapshot workspaces as slots; windows already
          # placed consume their slot, the rest fill what remains (exact title
          # first, then by count). Emits TSV: wid ws how app title.
          moves="$(printf '%s' "$current" | jq -rc \
            --argjson saved "$(cat "$layout")" \
            --argjson placed "$placed" '
            def rmws($x): (map(.ws) | index($x)) as $i | if $i == null then . else del(.[$i]) end;
            . as $cur
            | [ ($saved | group_by(.["app-bundle-id"])[])
                | .[0]["app-bundle-id"] as $app
                | [ .[] | {ws: .workspace, title: .["window-title"]} ] as $slots
                | [ $cur[] | select(.["app-bundle-id"] == $app) ] as $wins
                | [ $wins[] | select((.["window-id"] | tostring) as $id | $placed | has($id)) ] as $done
                | [ $done[] | $placed[.["window-id"] | tostring] ] as $consumed
                | (reduce $consumed[] as $c ($slots; rmws($c))) as $free0
                | [ $wins[] | select((.["window-id"] | tostring) as $id | ($placed | has($id)) | not) ] as $todo
                | (reduce $todo[] as $w ({free: $free0, out: []};
                     (.free | to_entries) as $fe
                     | ([ $fe[] | select(.value.title == $w["window-title"]) ][0]) as $ex
                     | ($ex // $fe[0]) as $pick
                     | if $pick == null then .
                       else .out += [{ wid: ($w["window-id"] | tostring), ws: $pick.value.ws, how: (if $ex then "exact" else "fill" end), cur: $w.workspace, app: $app, title: $w["window-title"] }]
                          | .free |= del(.[$pick.key])
                       end)).out
              ]
            | add // []
            | .[] | [.wid, .ws, .how, .cur, .app, .title] | @tsv
          ')" || { sleep 1; continue; }

          while IFS="$(printf '\t')" read -r wid ws how cur app title; do
            if [ -z "$wid" ]; then continue; fi
            ok=0
            if [ "$ws" = "$cur" ]; then
              ok=1                                   # already on its slot; just record it
            elif aerospace move-node-to-workspace --window-id "$wid" "$ws" >/dev/null 2>&1; then
              ok=1
              log "  placed win $wid -> ws$ws ($how: $app [$title])"
            else
              log "  FAILED win $wid -> ws$ws ($app)"
            fi
            if [ "$ok" = 1 ]; then
              if np="$(printf '%s' "$placed" | jq -c --arg k "$wid" --arg v "$ws" '. + {($k): $v}')"; then placed="$np"; fi
            fi
          done <<< "$moves"

          # Re-spawn windows for allowlisted apps that under-restored (e.g.
          # terminals). Wait until an app's count has settled so we don't race
          # macOS, then open each missing window exactly once.
          while IFS= read -r app; do
            [ -z "$app" ] && continue
            [ "''${spawned[$app]:-0}" = "1" ] && continue
            pc="$(printf '%s' "$current" | jq --arg a "$app" '[ .[] | select(.["app-bundle-id"] == $a) ] | length' 2>/dev/null || echo 0)"
            sc="$(jq --arg a "$app" '[ .[] | select(.["app-bundle-id"] == $a) ] | length' "$layout" 2>/dev/null || echo 0)"
            [ "$(( sc - pc ))" -le 0 ] && continue
            if [ "''${prevcount[$app]-x}" = "$pc" ]; then
              stable[$app]=$(( ''${stable[$app]:-0} + 1 ))
            else
              stable[$app]=0
            fi
            prevcount[$app]="$pc"
            if [ "''${stable[$app]:-0}" -ge "$settle" ]; then
              log "  respawn $app: $pc/$sc present -> open -n x$(( sc - pc ))"
              n=0
              while [ "$n" -lt "$(( sc - pc ))" ]; do
                open -n -b "$app" >/dev/null 2>&1 || log "  FAILED open -n -b $app"
                n=$(( n + 1 ))
              done
              spawned[$app]=1
            fi
          done < <(printf '%s' "$respawn" | jq -r '.[]')

          sleep 1
        done
      '';
    };
  in {
    options.myHomeModules.aerospace.respawnApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["net.kovidgoyal.kitty"];
      description = ''
        Bundle IDs (`aerospace list-apps`) whose windows the login restore
        should re-`open -n` when fewer come back than the snapshot recorded --
        i.e. apps with no native window restoration, like terminals. Apps that
        restore their own windows (Chrome, Slack, ...) must NOT be listed, or a
        spurious window is opened for every one they failed to bring back.
        Empty by default; opt in per host.
      '';
    };

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
            inner.horizontal = 5;
            inner.vertical = 5;
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
