{
  flake.modules.homeManager.fzf = {
    pkgs,
    lib,
    config,
    ...
  }: {
    config = {
      programs.fzf = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
        # FIXME: Doesn't work. Requires 'fd' to be available
        # in runtime
        # changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d";
        changeDirWidgetCommand = "fd --type d";
        changeDirWidgetOptions = [
          "--preview 'tree -C {} | head -200'"
        ];
        fileWidgetCommand = "fd --type f";
        fileWidgetOptions = [
          "--preview 'head {}'"
        ];
        historyWidgetOptions = [
          "--sort"
          "--exact"
        ];
      };
    };
  };
}
