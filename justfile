# Repo-level task runner. See `just --list` for available recipes.
#
# Recipes here support the experimental neovim rewrite documented in
# docs/NEOVIM_REWRITE.md. The stability gate (`just nvim-gate`) is the
# single most important invariant during the rewrite: cimmerian's
# wrapped neovim (`.#nvim`) must remain functionally equivalent to the
# captured baseline after every commit.

default:
    @just --list

# Capture cimmerian's wrapped neovim store path. Run once at the start of
# the rewrite branch; `.nvim-baseline.path` is gitignored.
nvim-baseline:
    nix build .#nvim --no-link --print-out-paths > .nvim-baseline.path
    @echo "baseline pinned to $(cat .nvim-baseline.path)"

# Rebuild .#nvim and confirm it's byte- or NVD-equivalent to the baseline.
# Run after every commit during the rewrite. Acceptable result: either
# "byte-equal: ok" or NVD reports "No version or selection state changes."
nvim-gate:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -f .nvim-baseline.path ]; then
      echo "no baseline; run 'just nvim-baseline' first" >&2
      exit 1
    fi
    baseline=$(cat .nvim-baseline.path)
    new=$(nix build .#nvim --no-link --print-out-paths)
    if [ "$baseline" = "$new" ]; then
      echo "byte-equal: ok"
    else
      nix run nixpkgs#nvd -- diff "$baseline" "$new"
    fi

# Run the experimental package locally.
nvim-exp:
    nix run .#nvim-experimental

# Headless smoke test: load the experimental wrapped nvim, run a one-liner, exit 0.
nvim-exp-smoke:
    nix run .#nvim-experimental -- --headless +'lua print("smoke: ok")' +q
