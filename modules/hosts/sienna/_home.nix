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

  home.packages = [
    pkgs.devenv
    pkgs.docker-client
    pkgs.docker-compose
    (pkgs.callPackage (inputs.self + /packages/by-name/v/vf) {})
  ];

  # Headless Docker engine via Colima (launchd brings it up at login,
  # replacing Docker Desktop). Colima comes from Homebrew — its VM tooling
  # needs macOS virtualization entitlements the nixpkgs build lacks; the
  # docker CLI/compose stay on nixpkgs.
  launchd.agents.colima = {
    enable = true;
    config = {
      ProgramArguments = ["/opt/homebrew/bin/colima" "start" "--foreground"];
      RunAtLoad = true;
      KeepAlive = true;
      EnvironmentVariables.PATH = "/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/colima.out.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/colima.err.log";
    };
  };

  # Override the systemConstants default (Linux-flavoured `/home/...`)
  # for nh's flake-path resolution. Could be lifted into a darwin-aware
  # default in modules/system/constants when the second darwin host lands.
  systemConstants.repoPath = "/Users/${config.systemConstants.user}/nixos-dot";
}
