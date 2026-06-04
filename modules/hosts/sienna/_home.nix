{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = with inputs.self.modules.homeManager; [
    aerospace
    bash
    bat
    btop
    direnv
    eza
    fd
    fish
    fzf
    gh
    git
    gitui
    kitty
    neovim
    nh
    nom
    ripgrep
    starship
    tmux
    yazi
  ];

  nixpkgs.config.allowUnfree = true;

  home.packages = [
    pkgs.claude-code
    (pkgs.callPackage (inputs.self + /packages/by-name/v/vf) {})
  ];

  # Override the systemConstants default (Linux-flavoured `/home/...`)
  # for nh's flake-path resolution. Could be lifted into a darwin-aware
  # default in modules/system/constants when the second darwin host lands.
  systemConstants.repoPath = "/Users/${config.systemConstants.user}/nixos-dot";
}
