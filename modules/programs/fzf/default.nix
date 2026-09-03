{
  flake.modules.homeManager.fzf = _: {
    config = {
      programs.fzf = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
        # FIXME: Doesn't work. Requires 'fd' to be available
        # in runtime
        # changeDirWidget.command = "${pkgs.fd}/bin/fd --type d";
        changeDirWidget = {
          command = "fd --type d";
          options = ["--preview 'tree -C {} | head -200'"];
        };
        fileWidget = {
          command = "fd --type f";
          options = ["--preview 'head {}'"];
        };
        historyWidget.options = [
          "--sort"
          "--exact"
        ];
      };
    };
  };
}
