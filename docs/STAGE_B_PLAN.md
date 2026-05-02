# Stage B — full canonical dendritic restructure

Plan-only document. Source: Doc-Steve dendritic-design-with-flake-parts wiki
(Basics, Dendritic_Aspects, Comprehensive_Example, FAQ, Acknowledgements).

## Goals

1. End state matches Doc-Steve canonical dendritic pattern.
2. NVD-equivalent against the pre-migration cimmerian baseline at every
   gate. The original baseline is
   `/nix/store/9gb2lbw6kqgrxdd2qbi4zjmjj5qgvzi3-nixos-system-cimmerian-25.11.20251116.50a96ed`.
3. One small commit per logical change (per-feature where possible).
4. Documentation lands alongside the structural change, not after.

## Namespace migration

| concern              | now (legacy / stage A)                                   | end (canonical)                                                   |
| -------------------- | -------------------------------------------------------- | ----------------------------------------------------------------- |
| nixos modules        | `flake.nixosModules.<name>`                              | `flake.modules.nixos.<name>`                                      |
| home-manager modules | `flake.homeModules.<name>`                               | `flake.modules.homeManager.<name>`                                |
| host as feature      | none — hosts live in mk-system.nix                       | `flake.modules.nixos.<host>` + `flake.nixosConfigurations.<host>` |
| user as feature      | inline in mk-system.nix                                  | `flake.modules.{nixos,homeManager}.jmfv`                          |
| feature opt-in       | `myHomeModules.<name>.enable = true/false`               | `imports = with self.modules.<class>; [ ... ];`                   |
| inheritance          | none                                                     | `system-types/`: default → essential → basic → CLI → desktop      |
| constants            | specialArgs (`user`, `base16Scheme`, `pkgs-master`, ...) | `flake.modules.generic.systemConstants` (Constants Aspect)        |
| factories            | none yet                                                 | `flake.factory.<name>` (Factory Aspect) for users, mounts, etc.   |

`flake.modules.<class>.<name>` is enabled by importing
`inputs.flake-parts.flakeModules.modules` from flake.nix.

## Final directory structure (target)

```
flake.nix                                # ~25 lines: inputs + mkFlake + import-tree
docs/
  MIGRATION.md                           # high-level history (existing, kept up to date)
  STAGE_B_PLAN.md                        # this doc
  ARCHITECTURE.md                        # how the tree is organized + how to add things
modules/
  flake/                                 # framework setup, no system-side config
    pkgs.nix                             # nixpkgs variants + overlays via _module.args
    lib.nix                              # mkNixos helper
    dev-shell.nix                        # devShells + templates
  programs/                              # mostly home-manager features
    eza/default.nix
    git/default.nix
    neovim/{default.nix,lua/...}
    spotify-player/{default.nix,_overlay.nix,_patches/...}
    ...
  desktop/                               # window managers, bars, launchers, theming
    i3/default.nix
    hyprland/default.nix
    polybar/{default.nix,sound.sh}
    waybar/default.nix
    ...
  services/                              # nixos services
    bluetooth/default.nix
    sound/default.nix                    # pipewire
    fonts/default.nix
    network-manager/default.nix
    laptop-power-management/default.nix
    virtual-fs/default.nix
    kmonad/{default.nix,kbd/...}
    spice-vda/default.nix
  system/                                # nixos system-level concerns
    doas/default.nix
    nix/default.nix
    timezone/default.nix
    internationalization/default.nix
    security/default.nix                 # the untracked draft, will land properly
    steam/default.nix
    constants/default.nix                # Constants Aspect: user, monitors, theme
    types/                               # inheritance chain, `system-types` analogue
      default.nix                        # baseline (any host)
      essential.nix                      # + impermanence, home-manager glue
      basic.nix                          # + cli minimal env
      cli.nix                            # + full CLI tool stack
      desktop.nix                        # + display/wm/audio/font
  hosts/
    cimmerian/default.nix
    t14g1/default.nix
    sartre/default.nix
    virt/default.nix
  users/
    jmfv/default.nix                     # flake.modules.nixos.jmfv (user account) + flake.modules.homeManager.jmfv (home defaults)
  factory/
    user/default.nix                     # parameterized user creation (later)
packages/                                # was customPkgs/, used via pkgs-by-name
  vf/...
  use/...
templates/
  basic/...
```

Bracket suffixes (`[N]`, `[ND]`, `[n]`, ...) are NOT used. They make
shell operations annoying and the wiki itself says naming is "arbitrary
and irrelevant" semantically. Each module's class is unambiguous from
which `flake.modules.<class>.<name>` it sets.

## Feature granularity

Rules of thumb — when in doubt, prefer a directory:

| feature shape                                                                                  | layout                                                                                                                                         |
| ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| single class, single file                                                                      | `<feature>/default.nix`                                                                                                                        |
| single class, helper assets (lua, kdl, scss, png, kbd)                                         | `<feature>/{default.nix, <assets>}`                                                                                                            |
| single class, helper Nix not meant to be a flake-parts module (e.g. nixpkgs overlays, patches) | `<feature>/{default.nix, _<helper>.nix}` — `_` makes import-tree skip                                                                          |
| spans nixos + home-manager                                                                     | `<feature>/default.nix` setting both `flake.modules.nixos.<name>` and `flake.modules.homeManager.<name>` (Multi-Context Aspect)                |
| spans nixos + home-manager AND large                                                           | `<feature>/{nixos.nix, home-manager.nix}` plus optional `default.nix` for cross-cutting; each file sets its own `flake.modules.<class>.<name>` |
| host                                                                                           | `hosts/<name>/default.nix` (single file usually). Hardware/disko stay underscored siblings: `_hardware-configuration.nix`, `_disko.nix`        |

We will NOT collapse modules/programs/eza into `modules/programs/eza.nix`
even though it could fit in one line — uniform `<feature>/default.nix`
makes adding assets later painless and matches the Doc-Steve example.

## Categorization (live mapping; refine during B4)

**modules/programs/** (mostly homeManager, CLI/GUI apps)

> alacritty, atuin, bash, bat, btop, delta, direnv, fd, firefox, fish,
> flameshot, fzf, gh, git, gitui, kitty, neovim, pet, ripgrep,
> spotify-player, starship, tmux, walker, wezterm, yazi, zathura, zellij,
> zoxide, zsh, eza

**modules/desktop/** (homeManager + a few nixos bits)

> i3, hyprland, picom, polybar, rofi, swaync, waybar, autorandr, eww,
> wofi, window-manager (the meta-feature)

**modules/services/** (nixos)

> bluetooth, sound, fonts, network-manager, laptop-power-management,
> virtual-fs, kmonad, spice-vda

**modules/system/** (nixos)

> doas, internationalization, nix, timezone, security, steam,
> constants, types/{default,essential,basic,cli,desktop}

**modules/hosts/** — cimmerian, t14g1, sartre, virt
**modules/users/** — jmfv

`window-manager` was a meta-feature switching between i3 and hyprland
based on `myHomeModules.window-manager.wm`. After B5/B6 it's replaced
by two meta-features: `desktop/i3-stack` and `desktop/hyprland-stack`,
each importing its sub-features. Hosts pick one.

## Phases (each ends with NVD gate)

Each phase ends with `nix build .#nixosConfigurations.cimmerian...`

- NVD diff against baseline. We commit only when the closure delta is
  zero and there are no version/selection changes. (We continue accepting
  hash drift from module evaluation order, just like stage A.)

### B1 — enable `flake.modules.<class>` namespace

- Add `inputs.flake-parts.flakeModules.modules` to flake.nix imports.
- Both legacy (`flake.{nixos,home}Modules.*`) and canonical
  (`flake.modules.<class>.*`) namespaces coexist.
- No content moved.
- **Gate:** cimmerian builds, NVD-equivalent.

### B2 — migrate home-manager namespace

- Per modules/home/\*.nix: rewrite
  `flake.homeModules.<name> = ...` as
  `flake.modules.homeManager.<name> = ...`.
- Drop the explicit `options.flake.homeModules` declaration in
  modules/flake/home-modules-option.nix once nothing references it.
- Update modules/flake/{mk-system,home-configurations}.nix to read
  `attrValues config.flake.modules.homeManager` instead of
  `config.flake.homeModules`.
- **Gate after each batch of ~5 modules:** NVD-equivalent.

### B3 — migrate nixos namespace

- Per modules/nixos/\*.nix: rewrite to `flake.modules.nixos.<name>`.
- Per host's `_configuration.nix`: rewrite
  `inputs.self.nixosModules.<name>` to
  `inputs.self.modules.nixos.<name>`.
- **Gate:** every host's drvPath stays the same.

### B4 — relocate to feature-colocated tree

- Move flat `modules/{home,nixos}/<name>` into
  `modules/{programs,desktop,services,system}/<name>/default.nix` per
  the categorization table above.
- Multi-file features (eww, polybar, zellij, neovim, spotify-player,
  kmonad) move whole directory.
- Single-file features get wrapped in their own dir with `default.nix`.
- One commit per logical group; build cimmerian after each.
- Update any references inside files that escape the dir
  (e.g. spotify-player's overlay, wallpaper image paths).
- **Gate:** after every group, NVD-equivalent.

### B5 — drop enable-flag pattern

- Per feature module: remove `options.myHomeModules.<name>.enable`,
  remove `lib.mkIf cfg.enable` wrapping, body becomes unconditional.
- Per host's `_home.nix`: replace the `myHomeModules = { ... }` block
  with `imports = with inputs.self.modules.homeManager; [ ... ];` listing
  exactly the features that resolved to enabled before. Anything
  cross-cutting (window-manager's monitors/statusBarMonitor) goes into a
  per-host inline config block (provisional — moves to constants in B8).
- Same for `myNixosModules.steam.enable` → either import the steam
  module or don't.
- The `window-manager` meta-feature is replaced with new meta-features
  `desktop/i3-stack` and `desktop/hyprland-stack` that import their
  sub-features.
- **Gate per host:** NVD-equivalent after each host's conversion.

### B6 — convert hosts to canonical feature modules

- `modules/hosts/<name>/_configuration.nix` becomes the host's
  `default.nix` setting `flake.modules.nixos.<name>` (the system) plus
  `flake.nixosConfigurations.<name>` (the deployable, via the new
  `inputs.self.lib.mkNixos` helper).
- `_home.nix` body folds into the host module via
  `home-manager.users.jmfv = { imports = [ self.modules.homeManager.jmfv
/* host-specific bits */ ]; }`.
- Drop `modules/flake/mk-system.nix` once all four hosts are converted.
- Drop `modules/flake/home-configurations.nix` and the
  `flake.homeConfigurations.jmfv` output — unused.
- Update `modules/flake/lib.nix` with the `mkNixos` helper.
- **Gate per host.**

### B7 — system-types inheritance

- Define `modules/system/types/{default,essential,basic,cli,desktop}.nix`,
  each setting `flake.modules.nixos.system-<level>` with imports of
  prior level + level-specific features.
- Hosts import their target level instead of listing every feature
  directly.
- **Gate per host conversion.**

### B8 — Constants Aspect

- `modules/system/constants/default.nix` declares
  `flake.modules.generic.systemConstants` with options:
  - `user = "jmfv"`
  - `base16Scheme` (per-host override)
  - `monitors` (per-host)
  - `statusBarMonitor` (per-host)
- Drop `user`, `base16Scheme` etc. from specialArgs in mkNixos helper.
- pkgs-master / pkgs-stable-\* still live in \_module.args (not constants
  — they're values, not strings).
- **Gate** after each constant migrated.

### B9 — Factory Aspect for the user

- `modules/factory/user/default.nix` declares `flake.factory.user`
  returning per-class user config.
- `modules/users/jmfv/default.nix` becomes a thin call site.
- **Gate.**

### B10 — Custom packages relocation

- Rename `customPkgs/` to `packages/` and adopt `pkgs-by-name` integration
  via a `modules/flake/packages.nix` that overlays
  `pkgs.callPackage`-discovered packages. Update consumers (cimmerian
  uses `vf` and `use`).
- **Gate.**

### B11 — documentation polish

- `docs/MIGRATION.md` updated section-by-section as B1..B10 land.
- `docs/ARCHITECTURE.md` written: explains `modules/<category>/<feature>/`,
  how to add a feature, how to add a host, where constants live,
  where to read/write factory definitions.
- Each `modules/<category>/` may grow a tiny README if helpful (NOT
  required; only if the category has non-obvious conventions).

### B12 — cleanup

- Delete `lspci.md` if it's not actually documentation for the repo (or
  move under `docs/`, your call).
- Verify `templates/` references in dev-shell.nix.
- Final NVD diff vs original baseline; record final cimmerian store
  path in MIGRATION.md.

## Sanity-check cadence

```fish
nix build .#nixosConfigurations.cimmerian.config.system.build.toplevel \
  --no-link --print-out-paths
nix run nixpkgs#nvd -- diff \
  /nix/store/9gb2lbw6kqgrxdd2qbi4zjmjj5qgvzi3-nixos-system-cimmerian-25.11.20251116.50a96ed \
  <new-path>
```

Required after every commit that touches a module or host. Acceptable
result: `No version or selection state changes. Closure size: X -> X
(...delta +0...)`. Anything else is a regression to investigate before
moving on.

## Risks and how we handle them

- **Module-evaluation-order hash drift:** already accepted in stage A.
  NVD-equivalence is the bar, not byte equality. (FAQ: dendritic doesn't
  promise hash stability across reorganizations.)
- **`lib.mkIf` around imports** is illegal per the wiki. Removing the
  enable-flag pattern naturally avoids this.
- **Cross-class dependencies** (e.g. nixos service requires a home-manager
  setting): use Multi-Context Aspect — single feature file sets both
  classes.
- **NVD is silent on `home.activation` script bodies:** if we change those
  unintentionally, NVD won't catch it. Spot-test with a switch+reboot at
  the end of each major phase (B2, B3, B4, B5, B6).
- **Loss of sartre standalone home-manager:** the
  `homeConfigurations.jmfv` block depends on sartre's `_home.nix`. After
  B6 it must point at the new sartre host module (or be rewritten as
  importing the user feature directly).

## Out of scope for stage B

- `vic/flake-file` adoption (auto-generated flake.nix). Optional; skip
  unless we discover it actually saves work.
- Bracket-suffix directory naming. Skipped.
- Darwin support. We have no Darwin machine.

## Resolved questions

1. `users/jmfv` is its own feature. `flake.modules.nixos.jmfv` creates
   the user account; `flake.modules.homeManager.jmfv` sets home defaults
   (font packages, stylix integration). Hosts import the user feature
   instead of inlining `users.users.jmfv` in mk-system.
2. `hardware-configuration-overrides.nix` stays as
   `modules/hosts/cimmerian/_hardware-configuration-overrides.nix` —
   underscored sibling alongside `_hardware-configuration.nix`.
3. Standalone `homeConfigurations.jmfv` is dropped in B6.
   `home-manager switch --flake .#jmfv` is unused. The flake output, the
   `home-configurations.nix` module, and the sartre `_home.nix` link in
   it all go away.
