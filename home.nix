{ config, pkgs, ... }:

{
  home.username = "jmfv";
  home.homeDirectory = "/home/jmfv";

  home.stateVersion = "22.11";

  # Packages to be installed
  home.packages = with pkgs; [
    exa
    fzf
    gitui
    zellij
    librewolf
  ];
  
}
