# nix-darwin

Reference notes for bringing an Apple Silicon Mac into this dendritic flake-parts
repo as a first-class fleet member. Written for a NixOS-on-Linux maintainer who
already speaks the local Aspect / `flake.modules.<class>.<name>` dialect and
just wants to know what changes on the Darwin side.

Targets nix-darwin as of mid-2026. Where a claim is time-sensitive it is marked
"verify on first install" and links to the upstream source.

## 1. What nix-darwin is (and isn't) in 2026

`nix-darwin` is the macOS analogue of NixOS's configuration module system:
`/etc`-management, launchd unit generation, `system.defaults` for the bits of
macOS that are normally tweaked with `defaults write`, a `darwin-rebuild`
build/activation entrypoint, and a flake output type
(`darwinConfigurations.<name>`). It does **not** replace the OS, the kernel, or
the bootloader; it sits on top of a normal macOS install and manages a Nix
profile plus a curated slice of system state.

- **Repo + maintainership.** Historically `LnL7/nix-darwin`. The transition to a
  community-owned `nix-darwin/nix-darwin` organisation that began in 2024 is
  effectively complete: the canonical fork lives at
  <https://github.com/nix-darwin/nix-darwin> with `LnL7/nix-darwin` redirecting.
  Treat `github:nix-darwin/nix-darwin` as the input URL going forward. Verify
  the redirect target on first install.
- **Release cadence.** Like nixpkgs, branched per release: `nix-darwin-24.05`,
  `nix-darwin-24.11`, `nix-darwin-25.05`, `nix-darwin-25.11` and a rolling
  `master`. Unstable users follow `master`; the branch name to pin against the
  matching `nixos-25.11`-style nixpkgs branch should be checked against the
  current README on first install.
- **CLI surface.** `darwin-rebuild switch --flake .#<host>` still works and is
  the documented happy path. The unified entrypoint
  `nix run nix-darwin -- switch --flake .#<host>` is supported on recent
  versions and is the right thing for first-install on a Mac that has Nix but
  has not yet had `nix-darwin` materialised. After the first activation
  `darwin-rebuild` is on `$PATH` and the two forms are equivalent.
- **macOS support.** Mid-2026 supports Sonoma 14.x, Sequoia 15.x, and Tahoe
  26.x (Tahoe shipped 2025-09-15). M5 Pro hardware ships with Tahoe 26.4 or
  newer. nix-darwin's Tahoe-compat PRs landed into master through autumn 2025
  and were backported to `nix-darwin-25.11` and `nix-darwin-26.05`. macOS 27
  is expected in autumn 2026 and will be the final release with full
  Rosetta 2; macOS 28 (2027) phases Rosetta 2 out for all but legacy gaming
  titles.

What it is **not**: a re-implementation of macOS APIs, a sandbox, or anything
that replaces Apple's launchd/PAM/profiles infrastructure. It writes config
files into `/etc` and `/Library/LaunchDaemons`, plants `launchctl` units, and
sets `defaults` through `osascript`/`defaults`. Everything macOS still owns
remains macOS-owned.

## 2. Nix-installer choice on Darwin

Four installers are in play. Pick deliberately, because the choice is sticky.

1. **Upstream nixos.org single-user installer.** Effectively unsupported on
   modern macOS: System Integrity Protection, signed-system-volume, the
   read-only `/` and the disappearance of the `nixbld` group all bite. Do not
   use.
2. **Determinate Systems `nix-installer`.** Until late 2025 the
   community-de-facto-standard for installing upstream CppNix on macOS.
   **As of early 2026 this installer no longer installs upstream Nix at
   all** -- DS dropped the `--prefer-upstream-nix` flag and the
   "Install Determinate Nix?" confirmation prompt now only branches into
   "install Determinate Nix" or "abort the installer entirely". If you run
   this installer today you get Determinate Nix (the fork, option 3 below),
   period. Reference:
   <https://determinate.systems/blog/installer-dropping-upstream/>. Source:
   <https://github.com/DeterminateSystems/nix-installer>.
3. **Determinate Nix (the fork).** Same installer binary, different flag, and
   different daemon image. Ships flake-schemas-aware tooling, lazy trees,
   "always-on flakes" defaults, and Determinate's own CA model. On Darwin the
   daemon plumbing is identical (a `launchd` service, an APFS volume); the
   user-visible difference is that `nix` is `determinate-nix` and that
   `flake.schemas` works. If you are deferring A.6 on Linux there is no strong
   reason to leap to Determinate Nix on Darwin first. Verify the current Darwin
   support matrix on <https://docs.determinate.systems/>.
4. **Lix.** A friendly fork. Installs cleanly on Darwin (multi-user, via the
   same `nix-installer` with a `--lix` style flag, or via Lix's own installer).
   Not blocked, but the nix-darwin module ecosystem is overwhelmingly tested
   against CppNix and Determinate Nix. Be prepared to file bugs if behaviour
   diverges. Source: <https://lix.systems/>.
5. **NixOS Foundation experimental installer.** Long-term destination per the
   Foundation, presently marked experimental. Same multi-user / APFS-volume
   shape as the Determinate installer, but Foundation-owned rather than DS-
   owned. nix-darwin gained support for it in PR #1702 (merged 2026-02-18,
   backported to `nix-darwin-25.11` in #1717). Invocation:
   `curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install`.
   Use today only if you want to dogfood the Foundation's tooling; the DS
   installer remains the lower-risk default. Source:
   <https://github.com/NixOS/experimental-nix-installer>.

Practical recommendation for this repo, mid-2026 (revised after DS dropped
upstream Nix): the three real choices are
**(option 5) NixOS Foundation experimental installer** for upstream CppNix
matching cimmerian/t14g1; **(option 3) DS installer** if you want Determinate
Nix (gets you lazy trees, flake-schemas, and avoids the open `$TMPDIR`
symlink bug #1577 on Tahoe); or **(option 4) Lix installer** if you want the
friendly fork. None of these choices propagate to other hosts: each machine
has its own Nix install, and the flake source is portable across all three.
The host-side `nix.package` option in nix-darwin declares which package
manages the daemon going forward, and should match what the installer put
down to avoid the installer-vs-config drift one-time replacement on first
activation.

Irreversibility: uninstall is supported (`/nix/nix-installer uninstall`) and
removes the volume, the daemon and the shell-init shims. Swapping installer
flavours mid-stream is technically possible but always means uninstall + clean
install; treat it as one-way.

## 3. Apple Silicon specifics

- **System identifier.** `aarch64-darwin`. Nix-darwin's `nixpkgs.hostPlatform`
  (or `nixpkgs.system`, legacy) must agree. There is no separate Rosetta
  identifier: x86_64 binaries run under Apple's Rosetta 2 at runtime but Nix
  evaluates them as `x86_64-darwin` and you'd have to add that to your
  `nixpkgs.config.allowedSystems` / cross-build setup if you want such packages
  available declaratively. For an `aarch64-darwin` host, do not enable
  x86_64-darwin by default; opt in narrowly when a specific package has no
  arm64 build.
- **Cross-arch builds inside the flake.** This repo's `modules/flake/pkgs.nix`
  currently hard-codes `system = "x86_64-linux"`. Adding a Mac means making
  that scope per-system, not adding a parallel hardcode. Two options: either
  parametrise `pkgs.nix` over `system` and call it from a `perSystem` block
  with `pkgs-master`/`pkgs-stable-*` materialised per-system, or build a
  thinner `pkgs-darwin.nix` that mirrors only the overlays that make sense on
  Darwin (the neovim-nightly overlay is supported on `aarch64-darwin`; the
  `vf`/`vfx` local packages need a one-line architecture-gate review). The
  second route is the smaller diff; the first is the right end-state when more
  than one mac shows up.
- **Tahoe / firmware caveats.** macOS Tahoe (26.x) shipped 2025-09-15 and is
  what M5 Pro hardware comes loaded with. The Tahoe-compat PRs are merged
  into master and backported to `nix-darwin-25.11` / `nix-darwin-26.05`. The
  open-issue tail is non-trivial: see §13 for known Tahoe-era footguns
  (TMPDIR symlink quirk, broken `mas` CLI, GUI session required for first
  activation). Pair the input branch with the matching nixpkgs branch
  (`nix-darwin-26.05` with `nixos-26.05`).
- **M5 Pro (2026 hardware) notes.** Announced 2026-03-02, available
  2026-03-11. 3 nm N3P process, ARMv9.2-A ISA, new "Fusion Architecture"
  bonding two dies in a single SoC. CPU base 15 cores (5 super + 10
  performance), up to 18 cores; GPU 16-20 cores with a Neural Accelerator
  per core; 16-core Neural Engine; LPDDR5X 9600 MT/s at 307 GB/s; up to
  64 GB unified memory (M5 Max is the 128 GB SKU). Thunderbolt 5
  (120 Gb/s), Wi-Fi 7 + Bluetooth 6 via the new on-package N1 chip. The
  system identifier is **still `aarch64-darwin`** -- the Fusion
  Architecture sits below the kernel boundary and does not affect Nix
  evaluation or substitution. No M5-specific knobs are needed in the host
  config; treat it as a generic `aarch64-darwin` target.
- **direnv / lorri.** Both work fine on `aarch64-darwin`. `services.lorri` is
  available via the nix-darwin module set but is generally not worth running
  in 2026; prefer `nix-direnv` driven by user-level `programs.direnv` in
  home-manager, exactly as on Linux. No Darwin-specific tweaks required.

## 4. `flake.darwinConfigurations.<name>` shape

The constructor lives at `inputs.nix-darwin.lib.darwinSystem` and is the
straight analogue of `nixpkgs.lib.nixosSystem`. Same `specialArgs` channel,
same `modules` list, same module-system semantics.

A minimal `mkDarwin`, mirroring this repo's `lib.mkNixos`
(`/home/jmfv/nixos-dot/modules/flake/lib.nix`), would look like:

```nix
flake.lib.mkDarwin = hostName:
  inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = {
      inherit inputs pkgs-master pkgs-stable-24-05 pkgs-stable-25-05;
    };
    modules = [
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew

      # Darwin-side overlays. Drop disko (irrelevant on macOS) and
      # nixos-wsl. stylix has a darwin-side darwinModules.stylix
      # output; opt in only after verifying the modules you use don't
      # silently no-op.
      {
        nixpkgs.hostPlatform = "aarch64-darwin";
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [
          inputs.neovim-nightly-overlay.overlays.default
          (final: _prev: {
            vf = final.callPackage (self + /packages/by-name/v/vf) {};
          })
        ];
      }

      self.modules.darwin.${hostName}
    ];
  };
```

Two things to note:

- **Disko and impermanence are dropped.** Neither has a Darwin module.
  APFS handles snapshots and Time Machine handles backups; the persistence
  Aspect at `/home/jmfv/nixos-dot/modules/system/persistence/default.nix` has
  no Darwin equivalent because root is durable on macOS.
- **`flake.modules.darwin.<name>` is a new class.** This repo already
  consumes `flake.modules.nixos.<name>` and `flake.modules.homeManager.<name>`
  via `flake-parts.flakeModules.modules` (wired by
  `flake-file.flakeModules.dendritic`, see
  `/home/jmfv/nixos-dot/modules/flake/inputs.nix`). The `flakeModules.modules`
  helper auto-registers any class name you reference, so writing
  `flake.modules.darwin.<host> = ...` in a dendritic module is enough; no
  per-class registration boilerplate is required. The `nvim` class in
  `modules/programs/neovim-experimental/factory/default.nix` already
  demonstrates this auto-registration for a non-standard class. Verify on first
  install by `nix flake show` after the first commit.

## 5. Run-as-root activation and `system.primaryUser`

This is the single biggest behavioural change in current nix-darwin versus
older READMEs and blog posts. As of mid-2025 master (shipped in
`nix-darwin-25.11` and `nix-darwin-26.05`), the **entire activation pipeline
runs as root**, not as the invoking user. Three consequences:

- **Every rebuild needs `sudo`.** `darwin-rebuild switch` without `sudo` now
  errors with `sudo: darwin-rebuild: command not found` -- this is the same
  root cause as the chronic open issue nix-darwin#1544. The correct
  invocations are:
  - First install: `sudo nix run nix-darwin -- switch --flake .#<host>`
  - Subsequent: `sudo darwin-rebuild switch --flake .#<host>`
- **`system.primaryUser` is now load-bearing.** Any option that historically
  applied to the user running `darwin-rebuild` (most `home-manager.*` wiring
  and a portion of `homebrew.*`) now applies to whichever username
  `system.primaryUser` names. The module enforces this with an assertion:
  build fails with a message listing exactly which options need a primary
  user. Set `system.primaryUser = "<your-username>"` on every host.
  Upstream documents this as a transition mechanism that may shrink later,
  but for now it is required.
- **`system.activationScripts.postUserActivation` was removed.** Any custom
  user-scoped activation needs an explicit `sudo -u "$PRIMARY_USER" ...`
  inside a regular activation script.

Reference: `modules/system/primary-user.nix` in the nix-darwin tree, and
issue <https://github.com/nix-darwin/nix-darwin/issues/1457>.

## 6. Home-manager integration

Three modes exist. This repo should pick (a) for the new Mac and keep (b) as a
documented escape hatch for B.3.

- **(a) HM as a nix-darwin module.** `home-manager.darwinModules.home-manager`
  is the analogue of `home-manager.nixosModules.home-manager` already imported
  by `mkNixos`. Wiring inside the darwin host file is identical to cimmerian:

  ```nix
  home-manager = {
    useGlobalPkgs = false;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs pkgs pkgs-master pkgs-stable-24-05 pkgs-stable-25-05;
      inherit user base16Scheme;
      system = "aarch64-darwin";
    };
    users.${user}.imports = [
      self.modules.homeManager.user
      ./_home.nix
    ];
  };
  ```

  Under the run-as-root activation model (§5), `system.primaryUser` must be
  set to the same `user` value, since `home-manager.users.${user}` is one of
  the options that requires a primary user. The build will fail with a clear
  assertion message if it is missing.

  This is the path that makes `flake.modules.homeManager.<feature>` modules
  shared between Linux and Darwin hosts -- the shared bash/git/fzf/yazi
  bundles in `modules/programs/` already evaluate on `aarch64-darwin`. Modules
  that touch Linux-only paths (xdg autostart files, autorandr, hyprland,
  polybar, picom, etc.) need either `lib.optionalAttrs pkgs.stdenv.isLinux`
  gates or they simply don't get imported by the Darwin host's `_home.nix`.
  The latter is cleaner: pick what you import per-host, do not retrofit
  cross-platform guards into every Linux-only module.

- **(b) Standalone HM (`homeConfigurations.<name>`).** B.3's
  `sartre-foreign` shape, applicable to a Mac whose system you do not own
  (corporate-managed, no-admin). Uses `home-manager.lib.homeManagerConfiguration`
  directly, no nix-darwin involvement. Future-proof escape hatch only;
  do not default to it on an owned device.
- **(c) Standalone HM under `nix-darwin`.** Not a real third mode -- it
  collapses to (a) once you have nix-darwin.

`useGlobalPkgs = false` matches every existing host in this repo and keeps
home-manager building its own `pkgs` instance with HM-specific overlays. Flip
to `true` only if you find yourself rebuilding the same package twice (system
profile + HM profile). `useUserPackages = true` matches existing hosts and
gets HM-installed packages into `~/.nix-profile`-style availability for the
GUI launcher.

## 7. Homebrew / Cask via `nix-homebrew`

There is a population of macOS apps that nixpkgs cannot package for licensing,
distribution-format, or arm64-coverage reasons: 1Password (the native app, not
the CLI), Docker Desktop, Arc, native Safari, Microsoft/Logitech vendor
utilities, JetBrains Toolbox, paid Mac App Store apps. On 2026 Apple Silicon
the gap is smaller than it was in 2022 but it is not zero.

`nix-homebrew` (<https://github.com/zhaofengli/nix-homebrew>) lets nix-darwin
own Homebrew itself: it materialises `/opt/homebrew` from a fixed-output input
so the brew binary, its prefix, and its taps are reproducible. The
`homebrew.*` option tree on top of that drives `brew install`
declaratively via the `nix-darwin` activation script.

The relevant inputs are:

```nix
flake-file.inputs = {
  nix-darwin.url = "github:nix-darwin/nix-darwin";
  nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  homebrew-core = {
    url = "github:homebrew/homebrew-core";
    flake = false;
  };
  homebrew-cask = {
    url = "github:homebrew/homebrew-cask";
    flake = false;
  };
};
```

Pinning the taps as flake inputs is the whole point: it removes Homebrew's
mutable rolling-tap update step from the loop, which is the single biggest
source of Homebrew non-determinism. `nix flake update homebrew-cask` is now
the only way Cask versions change.

A minimal declaration in the host file:

```nix
nix-homebrew = {
  enable = true;
  enableRosetta = false;
  user = config.systemConstants.user;
  taps = {
    "homebrew/homebrew-core" = inputs.homebrew-core;
    "homebrew/homebrew-cask" = inputs.homebrew-cask;
  };
  mutableTaps = false;
};

homebrew = {
  enable = true;
  onActivation = {
    autoUpdate = false;
    upgrade = false;
    cleanup = "zap";
  };
  casks = [
    "1password"
    "docker"
    "raycast"
  ];
  brews = [
    "mas"
  ];
};
```

Trade-off, with all four `cleanup` values (full enum from
`modules/homebrew.nix`):

- `"none"` (upstream default) -- leave everything alone. Imperative
  `brew install` survives activation.
- `"check"` -- drift-detection only. Activation fails loudly if the live
  install diverges from the declaration, no destructive action. Useful as a
  tripwire before flipping to `"uninstall"` or `"zap"`.
- `"uninstall"` -- run `brew bundle --cleanup` to uninstall anything not
  declared. Cask data files are left behind.
- `"zap"` -- run `brew bundle --cleanup --zap` to uninstall and delete all
  cask-associated files (preferences, support directories). Strictest
  posture, closest to a pure-nix install.

Pick deliberately. `"zap"` is the most declarative but reaps any ad-hoc
`brew install`; `"none"` keeps the imperative side-channel open at the cost
of allowing config drift; `"check"` is the diagnostic middle ground. Mac App
Store apps installed via `homebrew.masApps` are **never** removed regardless
of cleanup mode -- this is a Homebrew Bundle limitation called out in the
nix-darwin source.

`homebrew.onActivation.extraEnv` (added in nix-darwin PR #1745, merged
2026-05-03) injects extra environment variables into the brew invocation.
Useful for `HOMEBREW_NO_ENV_HINTS=1` and similar mute-the-noise toggles.

**Mac App Store via `homebrew.masApps` is currently broken** (as of early
2026). The `mas` CLI that nix-darwin shells out to relied on a private API
that Apple locked down in a Tahoe point release; `mas install <appid>` no
longer works. See <https://github.com/mas-cli/mas/issues/1029> and
<https://github.com/nix-darwin/nix-darwin/issues/1627>. The option still
exists and `nix-darwin` will happily generate the Brewfile, but activation
will fail when `mas install` errors. Until upstream `mas` is unblocked,
install Mac App Store apps imperatively via the App Store GUI (signed in
with your Apple ID). Such apps are not touched by `darwin-rebuild`
activation regardless of `cleanup` setting.

The "purely-nix-no-brew" posture is technically achievable -- nixpkgs's
`aarch64-darwin` coverage for CLI tools is excellent -- but it costs you
1Password (the GUI), Docker Desktop, and the Mac App Store integration. The
default fleet posture for this repo should be `homebrew` enabled for casks
only; CLI tooling stays in nixpkgs.

## 8. `system.defaults`

nix-darwin's option tree under `system.defaults` covers a curated slice of
what `defaults write` can set. Three sub-trees see most use:

- `system.defaults.NSGlobalDomain.*` (global preferences: key repeat, dark
  mode, scroll direction).
- `system.defaults.dock.*` (autohide, position, hot corners, magnification).
- `system.defaults.finder.*` (show extensions, show hidden files, default
  view, path bar).

A starter set worth pre-declaring on a fresh Mac:

```nix
system.defaults = {
  NSGlobalDomain = {
    AppleInterfaceStyle = "Dark";
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
    NSAutomaticSpellingCorrectionEnabled = false;
    NSNavPanelExpandedStateForSaveMode = true;
    "com.apple.swipescrolldirection" = false;
  };
  dock = {
    autohide = true;
    show-recents = false;
    tilesize = 36;
    mru-spaces = false;
  };
  finder = {
    AppleShowAllExtensions = true;
    AppleShowAllFiles = true;
    FXEnableExtensionChangeWarning = false;
    ShowPathbar = true;
  };
  screencapture.location = "~/Pictures/Screenshots";
};
```

Trade-off vs. ad-hoc `defaults write`: the nix-darwin tree only exposes the
common keys. For an obscure key you still drop to
`system.activationScripts.postActivation.text` with a literal `defaults write
com.apple.<something>`. The advantage of staying inside `system.defaults` is
that it survives `darwin-rebuild rollback`. Source for the option tree:
<https://daiderd.com/nix-darwin/manual/index.html> (the rendered options).

## 9. TouchID for sudo

Apple has historically wiped `/etc/pam.d/sudo` on point-release upgrades. The
nix-darwin option for "make TouchID for sudo survive macOS updates" is:

```nix
security.pam.services.sudo_local.touchIdAuth = true;
```

This writes to `/etc/pam.d/sudo_local`, which `/etc/pam.d/sudo` on Sonoma+
includes by default and which macOS upgrades **do not** clobber. The older
`security.pam.enableSudoTouchIdAuth` option (which patched `/etc/pam.d/sudo`
directly) is deprecated; do not use it on Sonoma or later. Reference:
<https://github.com/nix-darwin/nix-darwin/pull/787> and the option's own
description in the rendered manual. Verify the exact option path
(`sudo_local.touchIdAuth` vs. legacy form) on first install.

## 10. launchd agents

The NixOS systemd analogy is exact:

- `launchd.user.agents.<name>` is the macOS analogue of
  `systemd.user.services.<name>`. Runs in the user session, only while the
  user is logged in. The plist lands in `~/Library/LaunchAgents/`.
- `launchd.daemons.<name>` is the macOS analogue of `systemd.services.<name>`.
  Runs as `root` from system boot. The plist lands in
  `/Library/LaunchDaemons/`. Privileged services that need to run before
  login (sshd, a cache prefetcher, a metrics agent) go here.

The full option surface is documented as `launchd.daemons.<name>.serviceConfig`
and `launchd.user.agents.<name>.serviceConfig`; the option's keys map 1:1 to
launchd plist keys (StartInterval, KeepAlive, RunAtLoad, etc.), not to
systemd-unit semantics. Translate, don't transcribe.

## 11. Fleet integration plan for this repo

Concrete, file-by-file proposal. Pick a host name; this writeup uses
`<macname>` as a placeholder.

### 11.1 Inputs (via flake-file)

Edit `/home/jmfv/nixos-dot/modules/flake/inputs.nix` under
`flake-file.inputs`:

```nix
# nix-darwin master tracks nixpkgs-unstable, not nixos-unstable. These two
# channels diverge: nixos-unstable lags for Darwin compatibility (it's the
# NixOS-hydra branch), while nixpkgs-unstable tracks the cross-platform
# nixpkgs hydra. nix-darwin master will assertion-fail at evaluation if
# you point it at nixos-unstable. Carry a separate input so the Linux
# hosts can keep following nixos-unstable unchanged.
nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
nix-darwin = {
  url = "github:nix-darwin/nix-darwin";
  inputs.nixpkgs.follows = "nixpkgs-unstable";
};
nix-homebrew.url = "github:zhaofengli/nix-homebrew";
homebrew-core = {
  url = "github:homebrew/homebrew-core";
  flake = false;
};
homebrew-cask = {
  url = "github:homebrew/homebrew-cask";
  flake = false;
};
```

Then `nix run .#write-flake` to regenerate `flake.nix`, then `nix flake lock`.
Commit both. This is the same loop already documented in `inputs.nix`'s
header.

### 11.2 `modules/flake/lib.nix`

Add a sibling constructor next to `mkNixos`:

```nix
flake.lib.mkDarwin = hostName:
  inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = {
      inherit inputs pkgs-master pkgs-stable-24-05 pkgs-stable-25-05;
    };
    modules = [
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew

      {
        nixpkgs.hostPlatform = "aarch64-darwin";
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [
          inputs.neovim-nightly-overlay.overlays.default
        ];
      }

      self.modules.darwin.${hostName}
    ];
  };
```

Notes:

- No `disko`, no `nixos-wsl`, no `impermanence` here. None has a Darwin
  module; APFS + Time Machine fill the same role.
- Whether to import `inputs.stylix.darwinModules.stylix` is a per-host
  decision; some stylix targets are Linux-only. Import in the host file, not
  in `mkDarwin`.

### 11.3 `modules/flake/pkgs.nix`

The current file hardcodes `system = "x86_64-linux"`. The cleanest extension:
keep the existing Linux materialisation, and add a parallel
`aarch64-darwin` block exposed via `_module.args.pkgs-darwin` (and friends).
Per-system parametrisation is the right end-state but the diff stays small if
the second host's overlays are explicitly listed:

```nix
pkgs-darwin = import inputs.nixpkgs {
  system = "aarch64-darwin";
  config.allowUnfree = true;
  overlays = [ inputs.neovim-nightly-overlay.overlays.default ];
};
```

Then `_module.args.pkgs-darwin = pkgs-darwin;` and pass that into
`mkDarwin`'s `specialArgs` as the `pkgs` channel for darwin hosts. `pkgs-master`
and `pkgs-stable-*` can stay Linux-only until a darwin host actually needs
them; cross every bridge once.

### 11.4 Dendritic class registration and the `darwinConfigurations` output

Two distinct pieces of wiring, easy to conflate:

- **Module class auto-registration (free).** `flake-parts.flakeModules.modules`
  (wired by `flake-file.flakeModules.dendritic` in `inputs.nix`) auto-
  registers any class name referenced under `flake.modules.<class>.<name>`.
  The first `flake.modules.darwin.<name>` declaration in a dendritic module is
  enough; the `nvim` class already proves this for a non-standard class.
- **The `flake.darwinConfigurations` output (NOT free).** Unlike
  `nixosConfigurations`, flake-parts does **not** know about
  `darwinConfigurations` as a top-level flake output by default. You must
  import `inputs.nix-darwin.flakeModules.default` from `inputs.nix`:

  ```nix
  imports = [
    inputs.flake-file.flakeModules.dendritic
    inputs.nix-darwin.flakeModules.default
  ];
  ```

  Without this, `flake.darwinConfigurations.<host>` evaluates fine internally
  but `nix flake show` reports no such attribute, and `darwin-rebuild` cannot
  find the host. Easy to miss because the error is "attribute not found",
  not a nicely-worded module-system message.

Verify both pieces after the first commit by:

```
nix eval .#darwinConfigurations --apply 'c: builtins.attrNames c'
# => [ "<macname>" ]
```

### 11.5 First host: `modules/hosts/<macname>/default.nix`

The shipping shape, not pseudocode. Mirrors cimmerian's layout in
`modules/hosts/cimmerian/default.nix`:

```nix
{
  inputs,
  self,
  ...
}: let
  hostName = baseNameOf (toString ./.);
in {
  flake.modules.darwin.${hostName} = {
    config,
    pkgs,
    ...
  }: let
    inherit (config.systemConstants) user;
  in {
    imports = [
      self.modules.darwin.user
      # self.modules.darwin.tailscale  # once a darwin tailscale Aspect exists
    ];

    networking.hostName = hostName;
    networking.computerName = hostName;
    networking.localHostName = hostName;

    system.primaryUser = user;

    # Darwin's stateVersion is an integer, not "22.11"-style. Pin once,
    # never bump. See the nix-darwin manual under `system.stateVersion`.
    system.stateVersion = 6;

    security.pam.services.sudo_local.touchIdAuth = true;

    system.defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };
      dock.autohide = true;
      finder.AppleShowAllExtensions = true;
      screencapture.location = "~/Pictures/Screenshots";
    };

    nix-homebrew = {
      enable = true;
      user = user;
      taps = {
        "homebrew/homebrew-core" = inputs.homebrew-core;
        "homebrew/homebrew-cask" = inputs.homebrew-cask;
      };
      mutableTaps = false;
    };

    homebrew = {
      enable = true;
      onActivation.cleanup = "zap";
      casks = [ "1password" "docker" "raycast" ];
    };

    home-manager = {
      useGlobalPkgs = false;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit inputs;
        inherit user;
        system = "aarch64-darwin";
      };
      users.${user}.imports = [
        self.modules.homeManager.user
        ./_home.nix
      ];
    };
  };

  flake.darwinConfigurations.${hostName} = self.lib.mkDarwin hostName;

  flake.publicKeys.${hostName} = "ssh-ed25519 AAAA... jmfv.dev@gmail.com";
}
```

And a sibling `./_home.nix` that picks from `self.modules.homeManager.*`
excluding the Linux-only WM/desktop modules: bash, git, fzf, yazi, neovim,
direnv, starship, tmux are all safe.

### 11.6 Aspect compatibility

Aspect-by-Aspect verdict for the existing repo:

| Aspect (path)                                                                       | Darwin status                                                                                                                                                                                                                                                                                                                    |
| ----------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `modules/system/constants`                                                          | Reuse as-is; the `flake.modules.generic.systemConstants` class injects into any module that imports it, including darwin.                                                                                                                                                                                                        |
| `modules/system/persistence`                                                        | **Does not apply.** APFS is durable, root is not ephemeral. Do not import.                                                                                                                                                                                                                                                       |
| `modules/system/doas`                                                               | Does not apply; macOS sudo with TouchID replaces it.                                                                                                                                                                                                                                                                             |
| `modules/system/fonts`                                                              | Linux-only option path (`fonts.packages` is NixOS-side). On Darwin, drop fonts into `home-manager.users.<u>.home.packages` or use the Darwin-side `fonts.packages = [ ... ]` (which does exist on nix-darwin, with a smaller surface). Re-author as a generic Aspect or duplicate.                                               |
| `modules/system/internationalization`, `timezone`                                   | Darwin has `time.timeZone` and locale options under different paths; needs a darwin-class twin Aspect if you want a one-line knob. Otherwise inline in the host file.                                                                                                                                                            |
| `modules/system/known-hosts`                                                        | Linux-only (`programs.ssh.knownHostsFiles` lives on NixOS). The home-manager side (`programs.ssh.knownHosts`) is cross-platform; prefer that.                                                                                                                                                                                    |
| `modules/system/nix`, `nix-index`                                                   | The nix-index home-manager half works on darwin. The system-level `nix.settings` Aspect needs a darwin twin: `nix-darwin` has its own `nix.settings` option tree with mostly the same keys.                                                                                                                                      |
| `modules/services/tailscale`                                                        | **Needs a darwin twin.** `services.tailscale` (the option) is NixOS-only; the Darwin equivalent ships via `nix-darwin`'s `services.tailscale` module with a slightly narrower surface (no `extraSetFlags`-equivalent until upstream lands it). Write `flake.modules.darwin.tailscale` mirroring `flake.modules.nixos.tailscale`. |
| `modules/services/sound`, `bluetooth`, `network-manager`, `laptop-power-management` | Macos owns all of these; no Aspect needed.                                                                                                                                                                                                                                                                                       |
| `modules/services/kanata`                                                           | Has a documented macOS install path with `karabiner-driverkit-virtualhiddevice`. Out of scope for first activation.                                                                                                                                                                                                              |
| `modules/factory/user`                                                              | The `nixos` half is unusable on darwin (`users.users.<u>` has a different surface and is largely opt-in on macOS, since Apple owns the account). Add a sibling `homeManager` half (already cross-platform) and a thin `darwin` half that just registers the account at the system level if you need a non-default `home`.        |

The `flake.modules.darwin.user` referenced by the host file above is the new
darwin half of the user factory; it's a 5-line module that does little more
than `users.users.${user}.home = "/Users/${user}";` (and `shell` if you want
fish as login shell). Build it next to `modules/users/jmfv/default.nix`.

### 11.7 First activation

On the freshly-installed Mac, with Nix daemon up and the flake repo checked
out:

```
sudo nix run nix-darwin -- switch --flake .#<macname>
```

Three things to know going in:

- `nix run nix-darwin` is required for the _first_ activation -- the
  `darwin-rebuild` command does not exist on `$PATH` until the first
  generation has been built.
- The `sudo` prefix is required from the first command onwards (see §5).
  Without it you get the misleading `sudo: darwin-rebuild: command not
found` error.
- **Run from a graphical Terminal session, not over SSH.** The activation
  script needs the App Management TCC permission to manage
  `/Applications/Nix Apps/`; from a fresh SSH session it errors out instead
  of prompting. If you must do the first run over SSH, pre-grant "Allow
  full disk access for remote users" in System Settings > General > Sharing
  > Remote Login > the (i) info button. See `modules/system/applications.nix`
  > in the nix-darwin tree.

After first activation:

```
sudo darwin-rebuild switch --flake .#<macname>
sudo darwin-rebuild check  --flake .#<macname>   # dry-activate before switch
```

## 12. What you cannot do from nix-darwin

A short, blunt list. Save yourself the search.

- **Safari extensions.** Distributed via the Mac App Store and signed against
  Safari's bundle ID. No option for it; not even an activation-script hack
  works.
- **Anything inside `/System` or the signed system volume.** Read-only, sealed,
  cryptographically verified at boot. nix-darwin cannot touch it.
- **`/Applications/Safari.app`'s preferences beyond what
  `system.defaults.com.apple.Safari` exposes.** Some keys exist; many don't.
- **System Extensions / DriverKit drivers, kexts.** Require user approval in
  System Settings + reboot + signed identity. nix-darwin can drop the
  payload but the approval is interactive.
- **MDM profiles (`.mobileconfig`).** No option to install a configuration
  profile. macOS treats profile install as a privileged, interactive
  operation routed through `profiles` CLI or MDM.
- **Code-signing identities and notarisation secrets.** Live in Keychain.
  Keychain is not nix-managed; `security` CLI is. There is no
  `security.keychain.<name>` option tree.
- **FileVault enrolment, Touch ID enrolment, Apple ID sign-in.** Out of
  scope; interactive macOS flows.
- **`hosts(5)` entries that survive a Software Update.** Some macOS upgrades
  rewrite `/etc/hosts`; nix-darwin's `networking.hosts` is best-effort.

When in doubt: anything that requires either a signed-with-Apple-ID action,
a user-prompted approval in System Settings, or a write into `/System` is
out of reach.

## 13. Migration risk and rollback

- **Rollback is a profile generation rollback, not a bootloader rollback.**
  `darwin-rebuild rollback` (or `--rollback` on switch) restores the previous
  Nix profile and re-runs the activation script for that generation against
  current macOS state. It does not reboot, does not touch the recovery
  partition, does not undo a macOS Software Update. Treat it as "revert what
  nix-darwin changed", not "go back in time".
- **`darwin-rebuild check`** is the dry-activate analogue and is the right
  thing to run before `switch` on a remote / unattended Mac. It evaluates the
  flake and builds the toplevel without activating. There is no equivalent of
  NixOS's `boot` (queue-for-next-boot) target because activation on Darwin is
  not boot-coupled.
- **SSH lockout risk.** Activation does not touch sshd's host keys or the
  AuthorizedKeys path; macOS owns those. A botched nix-darwin generation
  generally leaves remote ssh working. The high-risk surfaces are
  `system.defaults.loginwindow` and `nix-homebrew` (a broken homebrew
  activation can fail the whole switch and leave the previous generation
  active, which is the safer failure mode). If you do brick the login flow,
  Recovery Mode + Terminal + `darwin-rebuild --rollback` is the escape hatch;
  verify on first install that you can do this from your specific Apple
  Silicon firmware revision.
- **State that activation can mutate destructively.** `homebrew.onActivation.cleanup
= "zap"` removes anything not declared. The `system.defaults` writes are
  destructive: a typo in `dock.autohide-delay` writes a wrong value, not an
  error. Treat the first activation like a first deploy: take the macOS
  Time Machine snapshot first.
- **`darwin-rebuild` does not gate on macOS version.** A nix-darwin
  generation that worked on Sonoma can break on the morning after a Tahoe
  upgrade, particularly around renamed defaults keys. Pin a known-good
  nix-darwin commit, do not auto-bump, and do `darwin-rebuild check` after
  every macOS upgrade.
- **TMPDIR symlink issue on macOS 26** (open: nix-darwin#1577). `nix flake
update` can fail with `failed to extract archive (Cannot extract through
symlink /tmp/nix-...)` because `/tmp` is a symlink to `/private/tmp` and
  recent upstream Nix tightened symlink traversal. Workaround at the host
  level:

  ```nix
  services.nix-daemon.tempDir = "/private/tmp";
  ```

  Determinate Nix does not exhibit this; upstream CppNix on Tahoe does. Pin
  the workaround until upstream fixes it.

- **First activation must run from a GUI session, not SSH.** Covered in §11.7
  above; mentioned again here because it is a silent footgun: the failure
  mode is "activation aborts" without an obvious cause. Pre-grant "Allow
  full disk access for remote users" in System Settings if SSH-only is the
  only option.
- **Mac App Store via `mas` is broken** (closed wontfix: nix-darwin#1627;
  upstream tracking: mas-cli/mas#1029). Apple locked down a private API.
  Install MAS apps imperatively via the App Store GUI; they survive
  `darwin-rebuild` unaffected, regardless of `homebrew.onActivation.cleanup`.

## References

Version-pin claims to verify on first install (link, what to check):

- nix-darwin org transition + canonical repo:
  <https://github.com/nix-darwin/nix-darwin> -- confirm `LnL7/nix-darwin`
  redirects.
- nix-darwin rendered options manual:
  <https://daiderd.com/nix-darwin/manual/index.html> -- confirm option names
  used above (`security.pam.services.sudo_local.touchIdAuth`,
  `system.defaults.*`, `launchd.daemons.*`, `nix-homebrew.*`).
- nix-darwin release branches:
  <https://github.com/nix-darwin/nix-darwin/branches> -- confirm the
  matching `25.11` / `26.05` branch name for your nixpkgs pin.
- Determinate Systems nix-installer:
  <https://github.com/DeterminateSystems/nix-installer> -- confirm
  multi-user-only on macOS, APFS volume default, uninstaller behaviour.
- Determinate Nix (the fork) docs: <https://docs.determinate.systems/> --
  confirm current Darwin support matrix and how to switch installer mode.
- Lix: <https://lix.systems/> -- confirm Darwin install path if exploring.
- home-manager `darwinModules.home-manager`:
  <https://github.com/nix-community/home-manager> -- confirm import path and
  `useGlobalPkgs`/`useUserPackages` semantics on darwin.
- nix-homebrew: <https://github.com/zhaofengli/nix-homebrew> -- confirm
  `nix-homebrew.darwinModules.nix-homebrew`, `mutableTaps`, the tap-as-input
  pattern.
- homebrew-core / homebrew-cask as inputs:
  <https://github.com/homebrew/homebrew-core>,
  <https://github.com/homebrew/homebrew-cask> -- confirm both publish
  consumable Git refs (they do; `flake = false`).
- sudo_local + TouchID survivability:
  <https://github.com/nix-darwin/nix-darwin/pull/787> -- confirm merged and
  exposed under `security.pam.services.sudo_local.touchIdAuth`.
- flake-parts modules helper (used for class auto-registration):
  <https://flake.parts/options/flake-parts-modules.html> -- confirm
  `flake.modules.<class>.<name>` works for arbitrary `<class>`.
- vic/flake-file dendritic module (already in this repo):
  <https://github.com/vic/flake-file> -- confirm `flakeModules.dendritic`
  still bundles `flake-parts.flakeModules.modules`.

Where a section above says "verify on first install", that's a deliberate
hedge: nix-darwin's option surface drifts faster than its manual gets
re-rendered, and macOS minor upgrades occasionally rename keys under
`system.defaults` without notice. The cost of one extra `darwin-rebuild
check` is small; the cost of a bricked first activation is a recovery-mode
side quest. Take the snapshot. Run the check. Then switch.
