{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.fzf;
in {
  options.myHomeModules.fzf = {
    enable =
      lib.mkEnableOption "enables fzf"
      // {
        default = true;
      };
  };
  config = lib.mkIf cfg.enable {
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
}
