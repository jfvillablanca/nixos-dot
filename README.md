## Architecture

- **flake-parts + vic/import-tree + vic/flake-file.** Every `.nix` file
  under `modules/` is auto-discovered as a flake-parts module. Inputs are
  declared per-feature and synthesized into `flake.nix` by a generator.
- **Dendritic pattern.** Doc-Steve's canonical layout - features under
  `modules/{programs,desktop,services,system,hosts,users,factory}/<name>/`,
  every feature is a directory. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
- **Custom packages** live in `packages/by-name/` (nixpkgs `pkgs-by-name`
  layout) and are surfaced via overlays in `modules/flake/`.

## Generating `flake.nix`

`flake.nix` is **auto-generated** by `vic/flake-file` from the
`flake-file.inputs.<name>` declarations spread across the tree
(`modules/flake/inputs.nix` for shared inputs, plus per-feature modules
for feature-local pins like `plugin-oil-nvim`).

```fish
nix run .#write-flake     # regenerate flake.nix from module declarations
nix flake lock            # lock new inputs (or `nix flake update <input>`)
```

Both must be committed together. `nix flake check` runs `check-flake-file`
which fails CI if `flake.nix` is stale w.r.t. the declarations. Treefmt
skips `flake.nix` (the generator owns its formatting).

## Caches

`nixos-dot.cachix.org` is published from CI (`.github/workflows/build-cache.yml`)
for the configured hosts. Public key + subscription wiring in
`modules/system/nix/`. Foreign machines: see comments at the top of that
file for `nix.conf` snippet.

## Docs

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - dendritic layout, namespaces, conventions.
