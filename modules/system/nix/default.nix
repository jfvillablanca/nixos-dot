{
  flake.modules.nixos.nix = {
    config,
    pkgs,
    inputs,
    ...
  }: {
    nix = {
      settings = {
        trusted-users = ["root" config.systemConstants.user];
        auto-optimise-store = true;
        substituters = [
          "https://hyprland.cachix.org"
          "https://nixos-dot.cachix.org"
          # "https://walker.cachix.org"
        ];
        trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "nixos-dot.cachix.org-1:EsmqDf88MC7iaxlCoKTmzVIu/Zm9gLtt+VXlbxaRtNI="
          # "walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="
        ];
        experimental-features = ["nix-command" "flakes"];
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 5d";
      };
      nixPath = ["nixpkgs=${inputs.nixpkgs}"];
      package = pkgs.nixVersions.stable;
    };
  };

  # darwin gets `nixPath` and nothing else. nix-darwin defaults it to
  # ["nixpkgs=flake:nixpkgs" "/nix/var/nix/profiles/per-user/root/channels"],
  # and that second entry does not exist on a channel-less setup -- so every
  # nix invocation opens with "warning: Nix search path entry
  # '/nix/var/nix/profiles/per-user/root/channels' does not exist, ignoring".
  # Pointing it at the flake's own nixpkgs silences that and makes `<nixpkgs>`
  # resolve to the same tree the flake builds against.
  #
  # The rest of the nixos block above is deliberately NOT shared: sienna runs
  # Lix, so `package` must not be forced from here, and nix-darwin spells the
  # gc schedule differently (`nix.gc.interval`, not `nix.gc.dates`).
  flake.modules.darwin.nix = {inputs, ...}: {
    nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];
  };
}
