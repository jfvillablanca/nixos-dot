{
  flake.modules.homeManager.aerospace = {
    lib,
    pkgs,
    ...
  }: let
    workspace = i: let
      n = toString i;
    in [
      (lib.nameValuePair "alt-${n}" "workspace ${n}")
      (lib.nameValuePair "alt-shift-${n}" "move-node-to-workspace ${n}")
    ];

    bindings =
      [
        (lib.nameValuePair "alt-enter" "exec-and-forget open -na ${pkgs.kitty}/Applications/kitty.app")

        (lib.nameValuePair "alt-left" "focus left")
        (lib.nameValuePair "alt-down" "focus down")
        (lib.nameValuePair "alt-up" "focus up")
        (lib.nameValuePair "alt-right" "focus right")

        (lib.nameValuePair "alt-shift-left" "move left")
        (lib.nameValuePair "alt-shift-down" "move down")
        (lib.nameValuePair "alt-shift-up" "move up")
        (lib.nameValuePair "alt-shift-right" "move right")

        (lib.nameValuePair "alt-f" "fullscreen")
        (lib.nameValuePair "alt-shift-f" "layout floating tiling")
        (lib.nameValuePair "alt-shift-space" "enable toggle")
        (lib.nameValuePair "alt-y" "layout tiles horizontal vertical")
        (lib.nameValuePair "alt-shift-q" "close")
      ]
      ++ lib.concatMap workspace (lib.range 1 9);
  in {
    config = {
      programs.aerospace = {
        enable = true;
        launchd.enable = true;
        settings = {
          gaps = {
            inner.horizontal = 8;
            inner.vertical = 8;
            outer.left = 8;
            outer.right = 8;
            outer.top = 8;
            outer.bottom = 8;
          };
          mode.main.binding = builtins.listToAttrs bindings;
        };
      };
    };
  };
}
