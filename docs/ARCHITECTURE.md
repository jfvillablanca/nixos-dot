# Architecture

This repo follows the **dendritic pattern** on top of `flake-parts` +
`vic/import-tree`. `flake.nix` is a thin wrapper; every `.nix` file
under `modules/` is auto-discovered and treated as a flake-parts module.
References:

- [Doc-Steve/dendritic-design-with-flake-parts wiki](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki)
- [vic/dendritic Nix](https://vic.github.io/dendrix/Dendritic.html)
- [hercules-ci/flake-parts](https://flake.parts)

## Tree

```
flake.nix                                # inputs + mkFlake + import-tree
.sops.yaml                               # sops-nix recipients (public age keys only)
secrets/
  <name>.yaml                            # sops-encrypted secret (ciphertext, git-tracked)
docs/
  MIGRATION.md                           # phase-by-phase history
  STAGE_B_PLAN.md                        # canonical-restructure plan
  ARCHITECTURE.md                        # this doc
modules/
  flake/                                 # framework wiring; sets no system config
    pkgs.nix                             # nixpkgs/nixpkgs-master/etc + overlays via _module.args
    lib.nix                              # flake.lib.mkNixos helper
    dev-shell.nix                        # devShells + flake.templates
  factory/
    user/default.nix                     # flake.factory.user — parameterized user feature factory
  users/
    jmfv/default.nix                     # calls factory.user "jmfv" → flake.modules.{nixos,homeManager}.jmfv
  programs/                              # user-facing applications (mostly homeManager)
    <feature>/default.nix
    neovim/{default.nix, lua/...}
    spotify-player/{default.nix, _overlay.nix, _patches/...}
    zellij/{default.nix, configs/...}
  desktop/                               # window managers, bars, launchers, theming
    <feature>/default.nix
    eww/{default.nix, config/...}
    polybar/{default.nix, sound.sh}
    wallpapers/{default.nix, *.png|jpg}
    i3-stack/default.nix                 # meta-feature: imports i3 + picom + polybar + ...
    hyprland-stack/default.nix           # meta-feature: imports hyprland + waybar + swaync + ...
    window-manager/default.nix           # data-only: declares monitors + statusBarMonitor options
  services/                              # nixos services
    <feature>/default.nix
    kmonad/{default.nix, kbd/*.kbd}
  system/                                # nixos system-level concerns
    <feature>/default.nix
    constants/default.nix                # flake.modules.generic.systemConstants — Constants Aspect
    sops/default.nix                     # sops-nix secrets (per-host age key on /persist)
    types/{default,cli,desktop}/default.nix  # inheritance hierarchy
  hosts/
    <hostname>/{default.nix, _hardware-configuration.nix, _disko.nix, _home.nix}
    # default.nix is the flake-parts module declaring both
    #   flake.modules.nixos.<name> (the system module) and
    #   flake.nixosConfigurations.<name> (the deployable, via self.lib.mkNixos)
    # The _-prefixed siblings are legacy NixOS / home-manager modules
    # imported by default.nix; import-tree skips them.
packages/
  by-name/                               # nixpkgs pkgs-by-name layout
    v/vf/default.nix
    u/use/default.nix
templates/
  basic/                                 # `nix flake init -t .#basic` source
```

### Convention: every feature is a directory

Even single-line features get their own `<feature>/default.nix`
directory. Uniform shape, makes adding assets later painless.

### Convention: `_`-prefix means "skip me"

`vic/import-tree` ignores any path containing `/_`. Use it for files in
the dendritic tree that are NOT flake-parts modules:

- raw NixOS / home-manager module files imported by a feature
  (`modules/hosts/<host>/_configuration.nix`,
  `modules/hosts/<host>/_home.nix`)
- nixpkgs overlays loaded explicitly
  (`modules/programs/spotify-player/_overlay.nix`)
- patches consumed by an overlay
  (`modules/programs/spotify-player/_<patch>.patch`)

## Namespaces

| concept                    | namespace                                  |
| -------------------------- | ------------------------------------------ |
| home-manager modules       | `flake.modules.homeManager.<name>`         |
| nixos modules              | `flake.modules.nixos.<name>`               |
| cross-class shared modules | `flake.modules.generic.<name>`             |
| host as feature            | `flake.modules.nixos.<host>`               |
| user as feature            | `flake.modules.{nixos,homeManager}.<user>` |
| factory functions          | `flake.factory.<name>`                     |
| nixos systems (deployable) | `flake.nixosConfigurations.<host>`         |
| dev shell                  | `flake.devShells.x86_64-linux.default`     |
| templates                  | `flake.templates.basic`                    |
| `mkNixos` helper           | `flake.lib.mkNixos`                        |

`flake.modules.<class>.<name>` comes from
`inputs.flake-parts.flakeModules.modules`, imported in `flake.nix`.

## Aspect patterns in use

We use a subset of the dendritic aspect catalogue:

- **Simple Aspect** — most program / desktop / service / system features
  set `flake.modules.<class>.<name>` directly.
- **Inheritance Aspect** — `modules/system/types/{default,cli,desktop}`
  form a chain: `system-default ⊂ system-cli ⊂ system-desktop`. Hosts
  pick a tier instead of cherry-picking every feature.
- **Constants Aspect** — `modules/system/constants/default.nix`
  declares `flake.modules.generic.systemConstants`. Imported by
  `system-default`. Today it carries `systemConstants.user`, read by
  `modules/system/nix/default.nix` (and any future feature that wants
  the username without pulling it through specialArgs).
- **Factory Aspect** — `modules/factory/user/default.nix` declares
  `flake.factory.user`, a function returning the
  `{nixos, homeManager}` module pair for a given username.
  `modules/users/jmfv/default.nix` consumes the factory and registers
  `flake.modules.{nixos,homeManager}.jmfv`.

## Wiring patterns

A homeManager feature module:

```nix
# modules/programs/eza/default.nix
{
  flake.modules.homeManager.eza.programs.eza = {
    enable = true;
    git = true;
    icons = "auto";
    extraOptions = ["--group-directories-first"];
  };
}
```

A nixos feature module:

```nix
# modules/system/doas/default.nix
{
  flake.modules.nixos.doas = {...}: {
    security.doas.enable = true;
  };
}
```

Hosts opt in by importing — no `myHomeModules.<x>.enable` flags. A host
module looks roughly like:

```nix
# modules/hosts/cimmerian/default.nix
{inputs, self, ...}: let
  user = "jmfv";
  base16Scheme = "spaceduck";
in {
  flake.modules.nixos.cimmerian = {pkgs, pkgs-master, ...}: {
    imports = [
      ./_hardware-configuration.nix
      ./_hardware-configuration-overrides.nix

      self.modules.nixos.jmfv               # user (factory-produced)
      self.modules.nixos.system-desktop     # tier
      self.modules.nixos.steam              # extras on top of the tier
    ];

    networking.hostName = "cimmerian";
    system.stateVersion = "22.11";

    # ... cimmerian-specific NixOS config (stylix, services, programs, etc) ...

    home-manager = {
      useGlobalPkgs = false;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit inputs pkgs pkgs-master /* ... */;
        inherit user base16Scheme;
        system = "x86_64-linux";
      };
      users.${user}.imports = [
        self.modules.homeManager.jmfv       # home defaults (factory-produced)
        ./_home.nix                          # cimmerian-specific home config
      ];
    };
  };

  flake.nixosConfigurations.cimmerian = self.lib.mkNixos "cimmerian";
}
```

`self.lib.mkNixos "<host>"` is the helper in `modules/flake/lib.nix`
that wraps `nixpkgs.lib.nixosSystem` with the standard framework
modules (disko, impermanence, stylix, nixos-wsl, home-manager) plus
overlays (neovim-nightly, spotify-player auth fix, local packages).

## Secrets (sops-nix)

Encrypted secrets use **sops-nix** (`modules/system/sops/default.nix`,
opt-in via `myNixosModules.sops.enable`). Nothing secret enters the Nix
store: secrets are committed as **ciphertext** under `secrets/*.yaml`,
decrypted at activation into `/run/secrets*` (tmpfs), and consumed by
path (e.g. `users.users.<u>.hashedPasswordFile`).

- **Decryption identity** — a dedicated per-host **age key** at
  `/persist/secrets/age/keys.txt` (0600 root:root), delivered
  out-of-band like the tailscale authkey, so it survives the
  ephemeral-root wipe and needs no sshd. `sops.age.keyFile` is a quoted
  string (type `pathNotInStore`; a path literal would copy into the
  store and be rejected). Chosen over ssh-to-age because headless hosts
  (rue) run Tailscale SSH with openssh off — there is no `/etc/ssh` host
  key to derive from (sops-nix imports none when openssh is disabled).
- **Recipients** — repo-root `.sops.yaml` (public keys only; read by the
  `sops` CLI, not by Nix). Each secret encrypts to the **host key + a
  universal admin key**; the admin key is the recovery / re-encrypt path
  if a host's `/persist` key is lost.
- **First consumer** — rue's login password: a `neededForUsers` secret
  → `/run/secrets-for-users/rue-password` → `hashedPasswordFile`, with
  `users.mutableUsers = false` making the sops hash authoritative.

Load-bearing constraints:

- `secrets/*` is excluded from treefmt (`modules/flake/treefmt.nix`) —
  prettier would reformat and corrupt the ciphertext. `secrets/` is
  still git-tracked (encrypted).
- Flakes see only git-tracked files, and sops-nix hashes the ciphertext
  at eval (`validateSopsFiles`) — `git add secrets/<f>.yaml` before any
  `nix eval` / rebuild.
- On an ephemeral-root host, `/persist` must be `neededForBoot = true`
  so the key is mounted before the users activation (the default
  activation branch has no `RequiresMountsFor` guard).
- **Bootstrap:** on a fresh install with `mutableUsers = false`, the age
  key must exist on `/persist` before the first `switch`, or the account
  is created with no valid password (`!`) → installer recovery. The
  two-phase rollout only nets a host that already has a working password.

## Adding things

### A new feature (program / desktop / service / system)

1. Pick a category: `programs/`, `desktop/`, `services/`, or `system/`.
2. Create `modules/<category>/<name>/default.nix` setting
   `flake.modules.<class>.<name> = {...}`. Class is `homeManager` for
   user-space tools, `nixos` for system-level config, `generic` for
   cross-class data.
3. If the feature spans both classes, set both attrs in the same file.
4. Asset files (lua, kdl, scss, png, kbd) live as siblings under the
   feature directory.
5. Helper Nix files that aren't flake-parts modules get a `_` prefix.
6. Hosts that want it add it to their `imports = [...]` list. Default
   inheritance tiers (`system-default`/`system-cli`/`system-desktop`)
   already cover the common ones.

### A new host

1. `mkdir modules/hosts/<name>` and create:
   - `_hardware-configuration.nix` — generated by `nixos-generate-config`
   - `_disko.nix` — disko layout (optional)
   - `_home.nix` — host-specific home-manager bits (optional)
   - `default.nix` — the flake-parts module that declares
     `flake.modules.nixos.<name>` and
     `flake.nixosConfigurations.<name> = self.lib.mkNixos "<name>"`.
     Use one of the existing hosts as a template.
2. Pick a system tier (`system-default` / `system-cli` /
   `system-desktop`) and add any extras (e.g. `kmonad`, `doas`,
   `laptop-power-management`).
3. Pick a desktop stack via `i3-stack` or `hyprland-stack` (if you
   want a graphical session).
4. Build: `nix build .#nixosConfigurations.<name>.config.system.build.toplevel`.

### A new user

1. `mkdir modules/users/<name>` and create `default.nix`:
   ```nix
   {self, ...}: let
     u = self.factory.user "<name>";
   in {
     flake.modules.nixos.<name> = u.nixos;
     flake.modules.homeManager.<name> = u.homeManager;
   }
   ```
2. Hosts that should provision the user import
   `self.modules.nixos.<name>` in the host module imports and
   `self.modules.homeManager.<name>` in the home-manager
   `users.<name>.imports`.
3. Per-host adjustments (e.g. `users.users.<name>.initialPassword`,
   `users.users.<name>.uid`) go on top of the factory base.

### A new secret

1. If a new host will consume it, generate its age key
   (`age-keygen`), put the **public** key in `.sops.yaml`, and deliver
   the **private** key out-of-band to `<host>:/persist/secrets/age/keys.txt`
   (0600 root:root). Existing hosts already have their key.
2. Add a `creation_rules` entry in `.sops.yaml` mapping the file to its
   recipients (`[admin, <host>]`), then author it:
   `sops secrets/<name>.yaml`. The top-level YAML key should equal the
   sops secret name so the default `key = <name>` lookup applies (no
   `.key` override). Regenerate an existing file's recipients with
   `sops updatekeys secrets/<name>.yaml`.
3. In the host: `myNixosModules.sops.enable = true;`, set
   `sops.defaultSopsFile`, declare `sops.secrets.<name>` (add
   `neededForUsers = true` for anything the user-creation activation
   needs, e.g. a password), and consume `config.sops.secrets.<name>.path`.
4. `git add secrets/<name>.yaml .sops.yaml` before evaluating (flakes
   only see tracked files, and eval hashes the ciphertext).

### A new local package

1. Drop the package definition under
   `packages/by-name/<first-letter>/<package>/default.nix` following
   the standard nixpkgs `pkgs-by-name` layout. Use
   `pkgs.callPackage`-style arguments.
2. Register it in the overlay in both `modules/flake/pkgs.nix`
   (the `_module.args.pkgs` flake-parts modules see) and
   `modules/flake/lib.nix`'s `mkNixos` (the `nixpkgs.overlays` each
   system uses).
3. Hosts then reference it as `pkgs.<name>`.

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
