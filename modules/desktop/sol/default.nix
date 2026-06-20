# Sol -- open-source macOS launcher (ospfranco/sol), the rofi analogue here.
# No nixpkgs darwin build exists, so the app comes from Homebrew; its scripts
# dir is the one plain-file, live-watched config surface, so that is all Nix
# manages. Everything else (hotkey, theme) stays in Sol's own GUI state.
{
  flake.modules.darwin.sol.homebrew.casks = ["sol"];

  flake.modules.homeManager.sol = {
    lib,
    config,
    ...
  }: let
    cfg = config.myHomeModules.sol;
  in {
    # Sol's native app search activates the already-running instance (macOS is
    # single-instance), which yanks focus to whatever workspace it lives on.
    # Each entry here is emitted as a Sol "script item" under
    # ~/.config/sol/scripts: Sol reads the file *content* and runs it through
    # `/bin/zsh -l -c` (ShellHelper.swift), so e.g. `open -na <app>` spawns a
    # fresh window instead -- replicating rofi/dmenu launch behaviour. The
    # `# name:`/`# icon:` lines are Sol metadata (scripts.store.tsx), not shell.
    options.myHomeModules.sol.newWindowApps = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          command = lib.mkOption {
            type = lib.types.str;
            example = "open -na kitty";
            description = "Command Sol runs (via `/bin/zsh -l -c`) when the item is chosen.";
          };
          icon = lib.mkOption {
            type = lib.types.str;
            default = "";
            example = "🐱";
            description = "Emoji shown beside the item in Sol. Omit for none.";
          };
        };
      });
      default = {};
      description = ''
        rofi-style "open a new window" launcher items. The attr name is the
        label Sol shows; each becomes ~/.config/sol/scripts/<label>.sh.
      '';
    };

    config.xdg.configFile = lib.mapAttrs' (label: opts:
      lib.nameValuePair "sol/scripts/${label}.sh" {
        text = lib.concatStringsSep "\n" (
          ["# name: ${label}"]
          ++ lib.optional (opts.icon != "") "# icon: ${opts.icon}"
          ++ [opts.command ""]
        );
      })
    cfg.newWindowApps;
  };
}
