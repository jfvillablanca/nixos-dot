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
      dsh
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
      sol
      starship
      tailscale
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

  # sienna is the host with an Obsidian vault on it (synced from rue). No vault
  # path is configured anywhere: obsidian.nvim finds the vault by walking up
  # for the `.obsidian/` marker, so this is the whole opt-in. Left off on the
  # Linux hosts, which have no vault to edit.
  myHomeModules.neovim.obsidian.enable = true;

  # Materialised by sops at activation; see sops.secrets."deepseek-api-key" in
  # this host's default.nix. /run/secrets is a hardcoded constant of sops-nix's
  # darwin module, not a path this repo picks, so spelling it literally
  # duplicates no decision -- and home-manager modules cannot reach
  # darwin-class config to read .path from it anyway.
  myHomeModules.dsh.apiKeyFile = "/run/secrets/deepseek-api-key";

  # kitty has no native window restoration; the aerospace login restore
  # re-opens its missing windows so they can be placed back onto workspaces.
  # (Chrome is intentionally excluded: it only ever restores a single profile
  # picker, so respawning it just yields a stray window, not the lost ones.)
  myHomeModules.aerospace.respawnApps = ["net.kovidgoyal.kitty"];

  # Sol activates the running kitty (and jumps to its workspace); this script
  # item spawns a fresh instance on the current workspace instead -- the rofi
  # "open a new window" behaviour. `open -na` needs no PATH, resolves the app
  # via LaunchServices.
  myHomeModules.sol.newWindowApps.Kitty = {
    icon = "🐱";
    command = "open -na kitty";
  };

  home.packages = [
    pkgs.devenv
    (pkgs.callPackage (inputs.self + /packages/by-name/v/vf) {})
  ];

  # Override the systemConstants default (Linux-flavoured `/home/...`)
  # for nh's flake-path resolution. Could be lifted into a darwin-aware
  # default in modules/system/constants when the second darwin host lands.
  systemConstants.repoPath = "/Users/${config.systemConstants.user}/nixos-dot";
}
