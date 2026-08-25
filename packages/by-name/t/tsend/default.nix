# tsend: Taildrop send wrapper. `tailscale file cp` takes files only --
# directories are rejected outright, offline peers fail with no
# store-and-forward, and tagged nodes are ineligible because Taildrop is
# same-user only. The logic is Python (tsend.py); this wraps it with fzf and
# an interpreter on PATH.
#
# `tailscale` is deliberately NOT a runtimeInput: the CLI has to match the
# tailscaled the system planted, whose version is chosen by nixos/darwin
# config this package cannot read. A second pinned copy would invite a skew
# that stays invisible until it breaks. gnutar is likewise absent -- Python's
# tarfile covers --tar.
{
  lib,
  writeShellApplication,
  python3,
  fzf,
  ruff,
}:
writeShellApplication {
  name = "tsend";
  runtimeInputs = [python3 fzf];
  text = ''exec python3 ${./tsend.py} "$@"'';

  # writeShellApplication already gates the wrapper with `bash -n` plus
  # shellcheck, but that only ever sees the one-line exec. treefmt covers no
  # Python in this repo, so without this the real logic has no gate at all.
  # ruff's pyflakes rules (F) catch what matters -- undefined names, unused
  # imports -- at build time, so a typo fails `nix build` instead of surfacing
  # halfway through a transfer. postCheck appends to the existing checkPhase
  # rather than replacing it.
  derivationArgs.postCheck = ''
    ${lib.getExe ruff} check --quiet --select E,F ${./tsend.py}
  '';
}
