{ config, pkgs, ... }:

{
  home.username = "jmfv";
  home.homeDirectory = "/home/jmfv";

  home.stateVersion = "22.11";
  
  programs.home-manager.enable = true;

}
