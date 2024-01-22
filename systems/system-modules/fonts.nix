{ config, pkgs, ... }:
{
  # Fonts
  fonts.fonts = with pkgs; [
    source-code-pro
    font-awesome
    corefonts
    jetbrains-mono
    (nerdfonts.override {
      fonts = [
        "FiraCode"
        "JetBrainsMono"
      ];
    })
  ];

}
