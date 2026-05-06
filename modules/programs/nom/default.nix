# nix-output-monitor (nom) — replaces the default nix build progress
# output with a dependency-graph view. `nh os switch` / `nh home switch`
# auto-detect and use it. Direct usage: `nix build .#foo |& nom`.
{pkgs, ...}: {
  flake.modules.homeManager.nom = {
    home.packages = [pkgs.nix-output-monitor];
  };
}
