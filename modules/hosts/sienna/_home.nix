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

  # kitty has no native window restoration; the aerospace login restore
  # re-opens its missing windows so they can be placed back onto workspaces.
  # (Chrome is intentionally excluded: it only ever restores a single profile
  # picker, so respawning it just yields a stray window, not the lost ones.)
  myHomeModules.aerospace.respawnApps = ["net.kovidgoyal.kitty"];

  home.packages = [
    pkgs.devenv
    (pkgs.callPackage (inputs.self + /packages/by-name/v/vf) {})
  ];

  # Override the systemConstants default (Linux-flavoured `/home/...`)
  # for nh's flake-path resolution. Could be lifted into a darwin-aware
  # default in modules/system/constants when the second darwin host lands.
  systemConstants.repoPath = "/Users/${config.systemConstants.user}/nixos-dot";
}
