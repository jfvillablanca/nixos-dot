{
  inputs,
  config,
  pkgs,
  base16Scheme,
  ...
}: {
  imports =
    [inputs.stylix.homeModules.stylix]
    ++ (with inputs.self.modules.homeManager; [
      aerospace
      bash
      bat
      btop
      claudeCode
      direnv
      docker
      eza
      fd
      fish
      fzf
      gh
      git
      gitui
      kitty
      moonlight
      neovim
      nh
      nom
      ripgrep
      starship
      tmux
      yazi
      zoxide
    ]);

  nixpkgs.config.allowUnfree = true;

  stylix = {
    enable = true;
    enableReleaseChecks = false;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${base16Scheme}.yaml";
    opacity.terminal = 0.9;
  };

  gtk.gtk4.theme = config.gtk.theme;

  programs.moonlight.extraSettings = {
    General = {
      width = 3840;
      height = 2160;
      fps = 60;
      bitrate = 80000;
      videocfg = 2;
    };
  };

  myHomeModules.claudeCode.enable = true;

  # Apps with no native multi-window restore; the aerospace login restore
  # re-opens the missing windows so they can be placed back onto workspaces.
  # kitty restores nothing; Chrome collapses multi-profile windows to one
  # picker -- respawned Chrome windows land on the right workspaces but as
  # generic (profile-picker) windows, which is an accepted trade-off here.
  myHomeModules.aerospace.respawnApps = [
    "net.kovidgoyal.kitty"
    "com.google.Chrome"
  ];

  home.packages = [
    pkgs.devenv
    (pkgs.callPackage (inputs.self + /packages/by-name/v/vf) {})
  ];

  # Override the systemConstants default (Linux-flavoured `/home/...`)
  # for nh's flake-path resolution. Could be lifted into a darwin-aware
  # default in modules/system/constants when the second darwin host lands.
  systemConstants.repoPath = "/Users/${config.systemConstants.user}/nixos-dot";
}
