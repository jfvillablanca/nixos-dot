{pkgs, ...}: {
  fonts.packages = with pkgs; [
    source-code-pro
    font-awesome
    corefonts
    jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];
}
