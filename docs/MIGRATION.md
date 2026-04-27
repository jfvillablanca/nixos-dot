# Dendritic migration notes

Incremental migration of this NixOS flake to the dendritic pattern
(flake-parts + import-tree, layout per
[Doc-Steve/dendritic-design-with-flake-parts comprehensive example](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/Comprehensive_Example)).

This file is the durable cross-machine reference. The local Claude
auto-memory under `~/.claude/projects/-home-jmfv-nixos-dot/memory/` is
machine-local and not part of this record.

## Goals

- Same functional system after switch — NVD reports no version or
  selection changes vs. the pre-migration baseline. Bit-identical store
  paths are *not* required (module reordering causes hash drift even
  when content is unchanged).
- One small, reviewable commit per module so any port is trivially
  revertable.
- Pattern reusable across all hosts (cimmerian, t14g1, sartre, virt).
  Once migration completes, adding a new host = one feature-list file
  under `modules/hosts/<name>/`.

## Verify a port

```fish
nix build .#nixosConfigurations.cimmerian.config.system.build.toplevel \
  --no-link --print-out-paths
nix run nixpkgs#nvd -- diff <baseline-path> <new-path>
```

Pre-migration baseline (commit before phase 1):
`/nix/store/9gb2lbw6kqgrxdd2qbi4zjmjj5qgvzi3-nixos-system-cimmerian-25.11.20251116.50a96ed`

For sartre (or any host already in `nixosConfigurations`):
`nix build .#nixosConfigurations.sartre.config.system.build.toplevel`
should still produce something `nvd diff`-equivalent to its
pre-migration baseline.

## Architecture

### Stage A — decouple from legacy aggregators (in progress)

`flake.nix` is a thin `flake-parts.lib.mkFlake` wrapper that runs
`import-tree ./modules`. Every `.nix` file under `./modules` is a
flake-parts module (files/dirs starting with `_` are skipped by
import-tree by default).

`modules/legacy-bridge.nix` re-implements the original `mkSystem`
factory and keeps building from `./nixosModules`, `./homeModules`, and
`./hosts/<name>/{configuration,home}.nix`. As modules port out of those
aggregators they get exposed via `flake.homeModules.<name>` (and later
`flake.nixosModules.<name>`); the bridge appends every value of those
attrsets to the home-manager / nixos imports list.

Per-module port pattern (single-file home module `foo`):

1. Move `homeModules/foo/default.nix` to `modules/home/foo.nix`,
   wrapping its content as
   `{ flake.homeModules.foo = <original module>; }`.
2. Drop the `./foo` line from `homeModules/default.nix`.
3. `git rm -r homeModules/foo`.
4. Build cimmerian; commit.

Multi-file modules (assets alongside default.nix):

- Move the whole directory to `modules/home/<name>/`. Asset files
  (`.scss`, `.kdl`, etc.) are not `.nix` so import-tree ignores them.
- For directories that contain helper `.nix` files which are *not*
  flake-parts modules (e.g. `homeModules/spotify-player/overlay.nix`),
  rename them with a leading underscore (`_overlay.nix`) so
  import-tree skips them; update any callers (the bridge in
  spotify-player's case).

### Stage B — restructure to feature-colocated layout (later)

After stage A removes `./homeModules`, `./nixosModules`, and
per-host `configuration.nix`/`home.nix`, the flat `modules/home/` and
`modules/nixos/` directories will be reshaped into:

```
modules/
├── nix/flake-parts/        # framework helpers, lib, devShell, formatter
├── programs/<feature>/     # home-manager + nixos config for one program
├── services/<feature>/
├── system/{settings,system-types}/
├── hosts/<host>/default.nix    # declares which features apply
└── users/<user>/default.nix
packages/                   # was customPkgs/
```

with platform-context suffixes (`[N]`, `[D]`, `[ND]`; lowercase for
home-manager) on directory names. Stage B is `git mv` per feature plus
small option-namespace renames; verified by NVD.

## Conventions

- Commits are small ("home: port foo to dendritic tree") and never
  bundle a port with unrelated changes.
- No AI attribution trailers in commit messages.
- Untracked working-tree files (`hosts/cimmerian/disko.nix`,
  `hosts/defenestration/`, `lspci.md`,
  `nixosModules/system/security/`) are intentionally not part of any
  active config and are left alone during migration.
- `defenestration` is not in `nixosConfigurations`. If the migration
  conflicts with it, copy its current state to `legacy/defenestration/`
  with a README before deleting from the main tree.

## Progress

Track `git log --oneline` for module-level granularity. High-level
status:

- [x] Phase 1: dendritic root bootstrapped (`flake.nix` →
  `flake-parts.lib.mkFlake` + `import-tree ./modules`,
  `modules/legacy-bridge.nix` mirrors `mkSystem`).
- [x] Bridge wired with `flake.homeModules` accumulator.
- [ ] Stage A — port all entries from `homeModules/default.nix`
  (eza done; many more in flight; neovim last).
- [ ] Stage A — port `nixosModules/` entries.
- [ ] Stage A — collapse per-host `configuration.nix` / `home.nix`
  into `modules/hosts/<name>/default.nix` declaring features.
- [ ] Stage A — delete `./homeModules`, `./nixosModules`, legacy
  bridge.
- [ ] Stage B — restructure into feature-colocated layout.
