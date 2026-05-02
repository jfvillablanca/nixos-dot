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

For detail on the end-state layout, conventions, namespaces, and how
to add features/hosts/users, see [`docs/ARCHITECTURE.md`](ARCHITECTURE.md).

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
- `defenestration` was deleted (abandoned side project).
- Untracked working-tree files (`lspci.md`,
  `nixosModules/system/security/`) remain at the repo root and are not
  part of any active config. They get cleaned up in B12.

## Progress

Track `git log --oneline` for module-level granularity. High-level
status:

- [x] **Stage A** — decouple from legacy aggregators
  - [x] Phase 1: dendritic root bootstrapped (`flake.nix` →
    `flake-parts.lib.mkFlake` + `import-tree ./modules`).
  - [x] Bridge wired with `flake.homeModules` accumulator, then every
    home module ported into `modules/home/` and the legacy
    `./homeModules/default.nix` aggregator removed.
  - [x] Every `nixosModules/` entry ported into `modules/nixos/`.
  - [x] Hosts moved to `modules/hosts/<name>/` with underscore-prefixed
    legacy entry files; `(self + /homeModules)` and
    `(self + /nixosModules)` references in the bridge dropped.
  - [x] `homeModules/system/{xdg,wallpapers}` ported and the
    `./homeModules` directory removed.
  - [x] Bridge split into single-purpose `modules/flake/*` files.
- [x] **Stage B** — full canonical dendritic restructure
  - [x] B1: `inputs.flake-parts.flakeModules.modules` imported in
    `flake.nix`, enabling `flake.modules.<class>.<name>` namespace.
  - [x] B2: every home module migrated to
    `flake.modules.homeManager.<name>`; `home-modules-option.nix`
    deleted (flake-parts already declares the option).
  - [x] B3: every nixos module migrated to `flake.modules.nixos.<name>`;
    host imports rewritten from `inputs.self.nixosModules.<x>` to
    `inputs.self.modules.nixos.<x>`.
  - [x] B4: features relocated into feature-colocated tree under
    `modules/{programs,desktop,services,system}/<feature>/default.nix`;
    docs/ARCHITECTURE.md added.
  - [x] B5: `options.myHomeModules.<x>.enable` + `lib.mkIf cfg.enable`
    wraps dropped from every feature; hosts opt in by importing.
    `window-manager` made data-only; `desktop/{i3-stack,hyprland-stack}`
    meta-features take over the WM component bundling.
  - [x] B6: each host became a flake-parts module declaring both
    `flake.modules.nixos.<host>` and `flake.nixosConfigurations.<host>`
    via the new `self.lib.mkNixos` helper. `mk-system.nix` and
    `home-configurations.nix` deleted; the standalone
    `homeConfigurations.jmfv` output is gone.
  - [x] B7: `modules/system/types/{default,cli,desktop}` chain — hosts
    adopt a tier instead of cherry-picking every feature.
  - [x] B8: Constants Aspect — `flake.modules.generic.systemConstants`
    holds `user`; `modules/system/nix` reads it from `config`; `user`
    dropped from `mkNixos` specialArgs.
  - [x] B9: Factory Aspect — `flake.factory.user`; `modules/users/jmfv`
    calls it; hosts import `self.modules.{nixos,homeManager}.jmfv`
    instead of inlining `users.users.jmfv`.
  - [x] B10: `customPkgs/` renamed to `packages/by-name/`; an overlay
    in `modules/flake/{pkgs,lib}.nix` exposes `pkgs.vf` and `pkgs.use`.
  - [x] B11: docs polish — `docs/ARCHITECTURE.md` rewritten, this file
    refreshed; obsolete `_configuration.nix` files removed.
  - [ ] B12: final cleanup + NVD vs original baseline.
