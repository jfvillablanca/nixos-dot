{
  flake.modules.homeManager.fzf = {
    lib,
    options,
    ...
  }: let
    widgets = {
      # FIXME: Doesn't work. Requires 'fd' to be available
      # in runtime
      # changeDir.command = "${pkgs.fd}/bin/fd --type d";
      changeDir = {
        command = "fd --type d";
        options = ["--preview 'tree -C {} | head -200'"];
      };
      file = {
        command = "fd --type f";
        options = ["--preview 'head {}'"];
      };
      history.options = [
        "--sort"
        "--exact"
      ];
    };

    # home-manager unstable nests widget settings (`changeDirWidget.command`);
    # release-26.05 (work-ct's pin) only has the flat `changeDirWidgetCommand`
    # form. Emit whichever shape the evaluating home-manager declares.
    nested = options.programs.fzf ? changeDirWidget;
    flatSuffix = {
      command = "Command";
      options = "Options";
    };
    widgetOptions = name: settings:
      if nested
      then {"${name}Widget" = settings;}
      else lib.mapAttrs' (key: lib.nameValuePair "${name}Widget${flatSuffix.${key}}") settings;
  in {
    config = {
      programs.fzf =
        {
          enable = true;
          enableBashIntegration = true;
          enableZshIntegration = true;
          enableFishIntegration = true;
        }
        // lib.mergeAttrsList (lib.mapAttrsToList widgetOptions widgets);
    };
  };
}
