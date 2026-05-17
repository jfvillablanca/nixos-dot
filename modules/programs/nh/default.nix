# nh — ergonomic wrapper around `nixos-rebuild` / `home-manager` /
# `nix-collect-garbage`. `nh os switch`, `nh home switch`, `nh search`,
# `nh clean all`. Picks up `nom` automatically for nicer build output
# (see modules/programs/nom).
{
  flake.modules.homeManager.nh = {config, ...}: {
    programs.nh = {
      enable = true;

      # NH_FLAKE points nh at this flake by default — every `nh os switch`
      # / `nh home switch` invocation operates on it without needing
      # `--flake .`.
      flake = config.systemConstants.repoPath;

      # System-level `nix.gc.automatic = true` (modules/system/nix/default.nix)
      # already schedules weekly GC; don't double up at the per-user layer.
      clean.enable = false;
    };
  };
}
