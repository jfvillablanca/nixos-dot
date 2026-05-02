# Architecture

This repo follows the **dendritic pattern**
([reference](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki))
on top of `flake-parts` + `import-tree`. `flake.nix` is a thin wrapper;
every `.nix` file under `modules/` is auto-discovered by
[`vic/import-tree`](https://github.com/vic/import-tree) and treated as a
flake-parts module.

## Tree

```
flake.nix                                # inputs + mkFlake + import-tree
docs/
  MIGRATION.md                           # phase-by-phase history
  STAGE_B_PLAN.md                        # canonical-restructure plan
  ARCHITECTURE.md                        # this doc
modules/
  flake/                                 # framework wiring; sets no system config
    pkgs.nix                             # nixpkgs/nixpkgs-master/etc + overlays via _module.args
    mk-system.nix                        # transitional mkSystem factory + 4 nixosConfigurations sites
    home-configurations.nix              # standalone home-manager for jmfv (dropped in B6)
    dev-shell.nix                        # devShells + flake.templates
  programs/                              # user-facing applications (mostly homeManager)
    <feature>/default.nix
    neovim/{default.nix, lua/...}        # multi-file: helper assets
    spotify-player/{default.nix, _overlay.nix, _patches/...}
    zellij/{default.nix, configs/...}
  desktop/                               # window managers, bars, launchers, theming
    <feature>/default.nix
    eww/{default.nix, config/...}
    polybar/{default.nix, sound.sh}
    wallpapers/{default.nix, *.png|jpg}
  services/                              # nixos services
    <feature>/default.nix
    kmonad/{default.nix, kbd/*.kbd}
  system/                                # nixos system-level concerns
    <feature>/default.nix
  hosts/
    <hostname>/{_configuration.nix,_home.nix,_hardware-configuration.nix,_disko.nix,...}
    # underscore-prefix → import-tree skips; the bridge in modules/flake/mk-system.nix
    # imports them as plain NixOS / home-manager modules.
customPkgs/                              # custom Nix packages (renamed to packages/ in B10)
templates/
  basic/                                 # `nix flake init -t .#basic` source
```

### Convention: every feature is a directory

Even single-line features get their own `<feature>/default.nix`
directory. Uniform shape, makes adding assets later painless.

### Convention: `_`-prefix means "skip me"

`vic/import-tree` ignores any path containing `/_`. Use it for files in
the dendritic tree that are NOT flake-parts modules:

- raw NixOS module files imported by the bridge
  (`modules/hosts/<host>/_configuration.nix`)
- nixpkgs overlays loaded explicitly
  (`modules/programs/spotify-player/_overlay.nix`)
- patches consumed by an overlay
  (`modules/programs/spotify-player/_patches/...`)

## Namespaces

Both legacy and canonical flake outputs are populated. Canonical is the
target.

| concept | namespace |
|---|---|
| home-manager modules | `flake.modules.homeManager.<name>` |
| nixos modules | `flake.modules.nixos.<name>` |
| (planned, B6) host as feature | `flake.modules.nixos.<host>` |
| (planned, B6) user as feature | `flake.modules.{nixos,homeManager}.jmfv` |
| nixos systems (deployable) | `flake.nixosConfigurations.<host>` |
| dev shell | `flake.devShells.x86_64-linux.default` |
| templates | `flake.templates.basic` |

`flake.modules.<class>.<name>` is enabled by importing
`inputs.flake-parts.flakeModules.modules` from `flake.nix`.

## How modules wire up

A feature module looks like one of these:

```nix
# modules/programs/eza/default.nix — homeManager class
{
  flake.modules.homeManager.eza = {lib, config, ...}: let
    cfg = config.myHomeModules.eza;
  in {
    options.myHomeModules.eza = {
      enable = lib.mkEnableOption "enables eza" // {default = true;};
    };
    config = lib.mkIf cfg.enable {
      programs.eza = {enable = true; git = true; icons = "auto";};
    };
  };
}
```

```nix
# modules/system/doas/default.nix — nixos class, no enable flag (cherry-picked by hosts)
{
  flake.modules.nixos.doas = {...}: {
    security.doas.enable = true;
  };
}
```

The `myHomeModules.<name>.enable` pattern with `mkIf` will go away in
B5; after that, features are unconditional and hosts opt in by
*importing* the module rather than enabling a flag.

## How a host is currently built

`modules/flake/mk-system.nix` exposes a `mkSystem` factory that calls
`nixpkgs.lib.nixosSystem` with:

1. third-party modules from inputs (disko, impermanence, stylix, nixos-wsl)
2. an inline module setting `networking.hostName`, `users.users.<user>`,
   `system.stateVersion`
3. the host's `_configuration.nix` (a plain NixOS module)
4. `home-manager.nixosModules.home-manager` plus an inline configuration
   that registers `home-manager.users.<user>.imports` with the host's
   `_home.nix` plus every `flake.modules.homeManager.<name>` value

Each host's `nixosConfigurations.<host>` calls `mkSystem` with the
host-specific `hostName`, `base16Scheme`, and `hostDir` (pointing at
`modules/hosts/<host>`).

In B6 each host becomes its own flake-parts module declaring both
`flake.modules.nixos.<host>` (the system module) and
`flake.nixosConfigurations.<host>` (the deployable, via a new
`self.lib.mkNixos` helper). `mk-system.nix` will be deleted.

## Adding things

### A new feature

1. Pick a category: `programs/`, `desktop/`, `services/`, or `system/`.
2. Create `modules/<category>/<name>/default.nix` setting
   `flake.modules.<class>.<name> = {...}`.
3. If the feature spans both classes, set both attrs in the same file.
4. Asset files (lua, kdl, scss, png) live as siblings.
5. Helper Nix files that aren't flake-parts modules get a `_` prefix.

### A new host

(Will simplify after B6.) Today:

1. `modules/hosts/<name>/_configuration.nix` — plain NixOS module.
2. `modules/hosts/<name>/_home.nix` — plain home-manager module.
3. `modules/hosts/<name>/_hardware-configuration.nix` — generated by
   `nixos-generate-config`.
4. `modules/hosts/<name>/_disko.nix` — disko layout (optional).
5. Add a `mkSystem` call site in `modules/flake/mk-system.nix`.

### A new user

(Will exist after B6/B9.) For now, edit the inline user block in
`mkSystem` in `modules/flake/mk-system.nix`.

## Sanity check after any change

```fish
nix build .#nixosConfigurations.cimmerian.config.system.build.toplevel \
  --no-link --print-out-paths
nix run nixpkgs#nvd -- diff \
  /nix/store/9gb2lbw6kqgrxdd2qbi4zjmjj5qgvzi3-nixos-system-cimmerian-25.11.20251116.50a96ed \
  <new-path>
```

Acceptable: `No version or selection state changes. ...delta +0...`.

`9gb2lbw6...` is the original pre-migration cimmerian baseline. NVD
ignores ordering-induced hash drift; functional regressions show up as
version or selection changes.
