{ ... }:
{
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    changeDirWidgetCommand = "fd --type d";
  };
}
