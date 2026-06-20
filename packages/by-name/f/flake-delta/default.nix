# flake-delta: eval-only package-version diff between two flake.lock revisions,
# across all flake outputs (nixos + darwin configs, packages, devShells).
# The logic is Python (flake-delta.py); this wraps it with nix + git on PATH.
{
  writeShellApplication,
  python3,
  nix,
  git,
}:
writeShellApplication {
  name = "flake-delta";
  runtimeInputs = [python3 nix git];
  text = ''exec python3 ${./flake-delta.py} "$@"'';
}
