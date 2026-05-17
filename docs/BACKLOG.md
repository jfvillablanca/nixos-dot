# Backlog

Ranked-ish ideas for follow-up projects. Pick one, scope it, open a branch.
Items the user has explicitly flagged interest in are marked ★.

## A. System / boot / filesystem

- A.1 ★ **Disko + impermanence on cimmerian.** Already done on t14g1; cimmerian
  was skipped due to data-loss risk. Stage: prototype the disko layout in a
  VM (`nixos-test` or QEMU snapshot), introduce a `/persist` mount opt-in
  on a non-root volume first, then commit to ephemeral root once trusted.
- A.2 **Lanzaboote secure boot.** UEFI hosts only. Replaces systemd-boot with
  signed boot chain.
- A.3 **Btrfs subvolumes + snapper / btrbk.** Hourly snapshot rollback. Pairs
  well with impermanence.
- A.4 **nixos-hardware bumps.** Audit per-host imports; cimmerian likely
  missing CPU/GPU-specific tuning that t14g1 has.
- A.5 **NixOS-WSL hardening for sartre.** systemd, wsl.conf, win32-interop
  tuning, default user setup.
- A.6 **Determinate Nix adoption (per-host opt-in).** Trial DetSys' Nix
  fork on cimmerian, expand to t14g1 if stable. Unblocks L.4
  (flake-schemas) as a side-benefit.
  - **Shape.** Add `inputs.determinate` via flake-file (colocate to
    `modules/system/nix/default.nix`). Add option
    `myNixosModules.determinate.enable` (default `false`). Conditionally
    `imports = lib.optional cfg.enable inputs.determinate.nixosModules.default`.
  - **Conflict surface in our nix module:** drop
    `nix.package = pkgs.nixVersions.stable;` (DetSys's module sets
    `nix.package = inputs.nix.packages.<system>.default` at default
    priority — direct collision; remove ours or `lib.mkDefault` it).
    Pin `nix.registry.nixpkgs.to` back to our `nixos-unstable` so DetSys
    doesn't shadow `inputs.nixpkgs` with `flakehub.com/.../nixpkgs-weekly`.
  - **Pros.** Parallel evaluation (claimed 5× on eval-heavy work), lazy
    trees (claimed 3× wall-time on large repos), `flake.schemas` honored
    by `nix flake show` (per the flake-schemas README; **DetSys's own
    docs only describe schemas as a FlakeHub-website feature, so
    verify empirically before relying on this for L.4**).
  - **Cons / caveats.**
    - **Telemetry on by default** — sends OS/hw/lang/timezone +
      Sentry crash reports. Disable via `DETSYS_IDS_TELEMETRY=disabled`
      and/or `telemetry.sentry.endpoint=null`. Caveat from the docs:
      "disabling telemetry also disables our tooling for rolling out
      features, which means that some Determinate Nix features may not
      be available."
    - `/etc/nix/nix.conf` becomes DetSys-managed (`determinate-nixd`
      writes it). Our `nix.settings.*` lands in `nix.custom.conf` —
      the NixOS module handles this transparently
      (`environment.etc."nix/nix.conf".target = "nix/nix.custom.conf"`).
    - GC: `determinate-nixd` schedules its own (≥30 GB free target;
      steady-state 5–20%; urgent <5%). Our `nix.gc = { dates = "weekly"; }`
      may be subsumed.
    - Tooling: community `nix-eval-jobs` is incompatible — DetSys ships
      a fork. We don't currently use nix-eval-jobs, but flag for any
      future CI work.
    - FlakeHub Cache is paid + auth-required; not auto-enabled. Our
      cachix substituters keep working as primary cache.
    - Initial rebuild needs `--option extra-substituters https://install.determinate.systems`
      (only the first time, per DetSys docs).
  - **Validation plan.** Prototype on cimmerian only:
    `nixos-rebuild build` → `test` → confirm `nix --version` shows
    DetSys's, cachix substituters survive, `nix flake show` actually
    consumes `flake.schemas`. Only `switch` once verified. Reverting
    is "remove the import + rebuild" (no `/nix/store` migration).

## B. Sartre stabilization ★

Goal: a foreign-host-friendly NixOS-WSL config that's bootstrappable from
a fresh Windows install.

- B.1 **`flake.nixosConfigurations.sartre`.** Promote sartre from non-NixOS
  Ubuntu (today only runs `nix run .#nvim-experimental`) to a full
  NixOS-WSL host with home-manager.
- B.2 **Bootstrap via nixos-anywhere.** `nixos-anywhere --flake
github:.../#sartre <ssh-target>` deploys NixOS over SSH from any
  bootable kexec target. Pairs with NixOS-WSL tarball for the Windows
  case (import tarball → ssh in → nixos-anywhere from cimmerian).
  Live-USB equivalent for foreign machines.
- B.3 **`flake.homeConfigurations.sartre-foreign`.** Standalone home-manager
  for the non-NixOS path (Ubuntu/macOS hosts where you can't get NixOS
  but can install Nix). fish/git/starship/tmux/nvim portable subset.
- B.4 **Cachix smoke checklist.** First-run on sartre should never trigger a
  source build. Document the verification.
- ~~B.5 **Bootstrappable NixOS-WSL proving ground (`defenestration`).**~~
  Branched a minimal NixOS-WSL host (`modules/hosts/defenestration/`)
  paired with a `release-wsl-tarball` workflow that builds via
  `tarballBuilder` and publishes the `.wsl` to a rolling GitHub
  release tag. Validates the consumer-mode pull-from-`github:`
  and-rebuild loop without touching sartre. Promoting sartre to
  this flow is still B.1.
- B.6 **Safe pull-and-rebuild on the long-idle Windows sartre.**
  Existing install on a Windows box is pinned to a stale commit;
  HEAD's sartre eval has drifted (additive changes only as audited
  on 2026-05-15: declarative authorized_keys, declarative
  known_hosts, OSC 52 clipboard, nh + nom, systemConstants user
  refactor, `use` replaced by `comma`). Biggest unknown is the
  `nixos-wsl` input bump between the pinned lock and HEAD. Recipe
  before pulling:

  ```bash
  # 1. Note current pinned commit
  git rev-parse HEAD

  # 2. Eyeball the delta in sartre-relevant trees
  git fetch
  git diff HEAD origin/main -- \
    modules/hosts/sartre/ modules/users/jmfv/ \
    modules/system/ modules/programs/

  # 3. Pull, build only (no activation)
  git pull
  sudo nixos-rebuild build --flake .#sartre

  # 4. Stage for next boot without touching running generation,
  #    then reboot WSL from PowerShell (`wsl --shutdown`)
  sudo nixos-rebuild boot --flake .#sartre

  # 5. If anything breaks: rollback, or re-import previous tarball
  sudo nixos-rebuild switch --rollback
  ```

## C. Desktop / WM stack hot-swap ★

- C.1 **Stack modules under `modules/desktop/stacks/`.** Already partial
  (`i3-stack`, `hyprland-stack`). Add `gnome-stack`, `kde-stack`,
  `niri-stack` (scrolling wayland WM, https://github.com/YaLTeR/niri).
  Make mutually exclusive via assertion.
- C.2 **Per-host `desktop.stack = "hyprland"` option.** Single line switch.
  Cimmerian today is tied to i3; goal is one-line swap to hyprland or
  gnome.
- C.3 **Drop static monitor declarations.** Use kanshi (wayland) / autorandr
  (X) / hypr's monitor-add for runtime detection. Laptop docks → external
  displays auto-config without rebuilding.
- C.4 **Greeter abstraction.** `greetd` with selectable session list across
  stacks (so you can pick gnome/hyprland/i3 at the login screen).
- C.5 **Wayland-default for cimmerian.** Currently X (i3). Try hyprland on
  cimmerian once the stack abstraction lands.
- C.6 **xdg-portal consistency.** Per-stack portal wiring so file pickers
  etc. work regardless of which stack you're on.
- ~~C.7 **Carcosa QEMU+SPICE lab MVP.**~~ Replaced `virt` with
  `carcosa`, a bare-CLI QEMU+SPICE NixOS VM on cimmerian.
  Validates the iteration loop end-to-end:

  ```bash
  # on cimmerian
  nixos-rebuild build-vm --flake .#carcosa
  ./result/bin/run-carcosa-vm

  # on any tailnet peer (virt-viewer wired into t14g1's home)
  remote-viewer spice://cimmerian:5930
  ```

  MVP only; revisit to add WM variants once C.1 + C.2 land.

## D. Secrets ★

- D.1a **Declarative authorized_keys.** Public keys aren't secrets, so
  no sops needed. Set `users.users.<u>.openssh.authorizedKeys.keys` in
  the user module so every host trusts the same fleet of devices. NixOS
  reads both `~/.ssh/authorized_keys` and `/etc/ssh/authorized_keys.d/%u`
  by default — declarative entries layer on top of any manual ones.
- D.1b **sops-nix proper.** age key per host, encrypted yamls in
  `secrets/`. Migrate cachix token, copilot auth, github tokens, ssh
  _private_ keys, wifi credentials. Half-day project the first time:
  generate per-host age keys, derive a recipients list, write the
  `sops-nix` flake-parts wiring, encrypt-in-place each secret, swap
  hardcoded references to `config.sops.secrets.<name>.path`.
- D.2 **yubikey integration.** GPG-on-yubikey + SSH signing.
- D.3 **Audit current plaintext.** What's checked in today that shouldn't be.

## E. Backup / DR

- E.1 **restic + B2 / S3.** Per-host backup schedule, declarative.
- E.2 **`/home` snapshot strategy.** Pairs with btrfs subvolumes.
- E.3 **Disaster recovery runbook.** From blank disk to working host in N
  minutes; document for cimmerian + t14g1.

## F. CI / automation

- F.1 **nix-flake-update bot.** Renovate-style auto-PRs for input bumps.
  Filter to specific inputs; never auto-merge.
- F.2 **Matrix expansion.** `build-cache.yml` builds sartre + virt alongside
  cimmerian + t14g1.
- F.3 **VM smoke tests** (`nixos-lib.runTest`). Boot each host config in
  QEMU; assert services come up.
- F.4 **nixos-generators artifacts in CI.** `nix build .#packages.x86_64-linux.<host>-iso`
  via nixos-generators; closure pushes to cachix (already wired), final
  `.iso` uploads as a GitHub release asset. End-users `curl` the ISO
  without needing nix; nix-users build cached.
- F.5 **vulnix / cve-bin-tool.** Lockfile vulnerability audit on each PR.
- ~~F.6 **Lockfile flatten.**~~ _Won't-fix._ flake-file's `allfollow` and
  `nix-auto-follow` integrations both fail in our setup; not worth a
  custom prune-lock program for the marginal savings.
  - **allfollow (default config):** spikespaz/allfollow's own input is
    `nixpkgs-unstable` (a different branch from our `nixos-unstable`).
    When added, allfollow's nixpkgs claims the canonical `"nixpkgs"`
    lock-node name, displacing our `nixos-unstable` to `"nixpkgs_4"`.
    Transitive inputs that resolve via the path `["nixpkgs"]` (hyprland
    et al.) silently shift to a different revision — massive closure
    drift (binutils 2.46, glibc 2.42-61, gcc bumped, etc.). allfollow
    has no exemption flag (`--no-follows`/`-p`/I-O only) so we can't
    surgically opt-out specific inputs.
  - **allfollow with `inputs.nixpkgs.follows = "nixpkgs"`:** lock graph
    is correct (canonical `"nixpkgs"` stays our pin). But allfollow's
    build chain depends on oxalica/rust-overlay, which fails to build
    cargo against our newer `nixos-unstable` (FOD source-fetch error:
    `do not know how to unpack source archive .../unknown`). Tool
    itself can't be built.
  - **nix-auto-follow (fzakaria/nix-auto-follow, Python):** flake-file
    pre-pins its nixpkgs so the displacement bug doesn't fire; tool
    builds and runs cleanly. Toplevel hashes byte-identical. But the
    lock got _bigger_ (62→63 nodes, +18 lines), and several
    `flake-parts_X` entries had their `rev` rewritten to revisions
    that don't appear anywhere else in HEAD's lock. Net cost > net
    benefit; murky semantics.
  - **What to do instead.** F.6.0 (zen-browser removal +
    input-colocation) already delivered the real lock/closure win
    (cimmerian closure 19.1 → 17.6 GiB, –1.5 GiB). Manual
    `inputs.nixpkgs.follows = "nixpkgs"` lines in feature modules are
    the explicit, well-understood mechanism — keep them.

## G. Networking

- ~~G.1 **Tailscale or wireguard mesh.**~~ Cimmerian + t14g1 + sartre on the
  same overlay. Easier ssh, file transfer, distributed builds.
- G.2 **SSH config consolidation.** Per-host `programs.ssh.matchBlocks`,
  shared `known_hosts`.
- ~~G.3 **Distributed builds.**~~ Cimmerian as remote builder for t14g1
  (workstation has more cores).

## H. Self-hosted (optional)

- H.1 **atticd or harmonia.** Local nix binary cache. Reduces cachix
  dependency for personal infra.
- H.2 **vaultwarden / nextcloud.** If cimmerian is up reliably.
- H.3 **gitea / forgejo.** Private repo mirror.

## I. Dev environment

- ~~I.1 ★ **Replace `use` with `comma` + `nix-index-database`.**~~ Drop
  `packages/by-name/u/use/`. comma resolves by binary name (`, convert`
  → imagemagick) via prebuilt nix-index DB; the existing `use` script
  needs the attribute name. Module: import
  `inputs.nix-index-database.nixosModules.nix-index` + add `comma` to
  user packages.
- ~~I.2 ★ **nh (nixos-helper).**~~ Ergonomic rebuilds (`nh os switch`, `nh home
switch`). Replaces raw `nixos-rebuild` / `home-manager` calls.
- ~~I.3 ★ **nix-output-monitor (nom).**~~ Replaces the default build progress
  output. Nicer dependency-graph view. `nix build |& nom` or
  `nh os switch` (which uses nom by default).
- I.4 **devShells `.#dev-{rust,node,go,python}` for non-Nix repos.** Stack
  flakes here, gitignored `.envrc.local` in work/coworker repos that
  activates them via `use flake github:jfvillablanca/nixos-dot#dev-rust`.
  Lets you have devenv-style ergonomics on repos you can't add `devenv.nix`
  to.
- I.5 **`flake.templates.{rust,node,go,python}`.** Companion to the
  devShells above — `nix flake init -t github:.../#rust` for new
  projects.

## J. Editor LSP coverage on this repo

Stable nvim already has nixd + autocomplete for nixpkgs lib + NixOS
options (cimmerian) + home-manager options. Gaps:

- ~~J.1 **flake-parts options.**~~ No completion on `perSystem.<tab>` or
  `flake.modules.<class>.<name>`. Add `debug.enable = true;` somewhere
  under `modules/flake/` to expose the flake-parts option tree at
  `outputs.debug.options`, then point `nixd`'s `options.flake_parts.expr`
  at it.
- ~~J.2 **Factory args.**~~ No completion when editing the experimental factory
  call site. Expose `flake.lib.nvimOptions = eval.options` from the
  experimental aggregator (`modules/programs/neovim-experimental/factory/`)
  and add a matching `nixd.options.<name>.expr` entry.
- ~~J.3 **flake-file options.**~~ _Covered by J.1._ flake-file declares
  its options as a submodule at `flake-file.<...>` within the
  flake-parts top-level option tree. J.1's `flake_parts.expr =
'...debug.options'` already exposes `flake-file` as a submodule
  option at the top of `debug.options`; nixd handles submodule
  traversal natively for registered option trees, so
  `flake-file.inputs.<tab>` completion piggy-backs on the J.1 wiring.
  No additional code change. If nixd ever stops descending into
  submodules, expose
  `(builtins.getFlake "...").debug.options."flake-file".type.getSubOptions []`
  as a separate `flake_file.expr` entry.

Wire the new entries into both `modules/programs/neovim/lua/lsp/servers/nixd.lua`
(stable) and `modules/programs/neovim-experimental/lsp/servers/nixd/default.nix`
(experimental). Likely 2-3 small commits.

## K. Neovim post-promotion

(Once Phase 5 promotion of `.#nvim-experimental` ships.)

- K.1 **Lazy loader.** Consumes the `lazy.{event,cmd,ft,keys}` data already
  captured in plugin specs. `opt = true` plugins + `packadd` on trigger.
- K.2 **Project-aware none-ls.** `condition` callbacks for per-project tool
  selection (eslint local vs system, etc.).
- K.3 **Build variants.** `nvim-experimental-{minimal,full}` packages via
  factory + selective imports.
- K.4 **Spines for dap / formatters / linters.** Add when concrete plugin
  contributors land (currently configured inline).
- K.5 **Editable spine emission.** Replace `_spine_*` synthesized lua with
  proper rtp packdir entries so `:edit` lands on a real file.

## L. Dendritic-pattern explorations

- L.1 **More custom flake-parts classes.** Candidates: `wm` (window-manager
  modules), `dotfile` (non-NixOS dotfiles for sartre-foreign).
- L.2 **Granular inheritance tiers.** Current `system-default ⊂ system-cli ⊂
system-desktop` is coarse. Add `system-laptop`, `system-workstation`,
  `system-server` siblings.
- L.3 **Aspect catalog tour.** Doc-Steve's wiki has Profile Aspect, Slot
  Aspect, etc. that we haven't tried. Pick one and apply.
- L.4 **flake-schemas** (DeterminateSystems). _Blocked on A.6
  (Determinate Nix adoption)._ Upstream Nix (we run 2.31.2) doesn't
  honor `flake.schemas` — the experimental feature `flake-schemas`
  isn't recognized; `nix flake show` ignores the output entirely.
  flake-schemas's own README confirms: "Flake schemas are currently
  available only in Determinate Nix." DetSys's own docs only describe
  schemas as a FlakeHub-website feature; whether their `nix flake show`
  consumes `flake.schemas` is unverified — must test under A.6 before
  relying on this. The schemas module shape itself is straightforward
  (`version`, `doc`, `inventory : output -> { children = ...; }`); the
  effort lives entirely in resolving the prerequisite.

## M. Repo hygiene

- M.1 **`nixosModules/` draft.** _Deferred — blocked on L.2 (system-tier
  siblings)._ Sole content is `nixosModules/system/security/default.nix`
  (hlissner-borrowed). Audited and partitioned; resume after L.2:
  - **System tier (network hardening).** Keep:
    `net.ipv4.icmp_ignore_bogus_error_responses=1`;
    `net.ipv{4,6}.conf.all.accept_source_route=0`;
    `net.ipv4.conf.{all,default}.send_redirects=0`;
    `net.ipv{4,6}.conf.{all,default}.accept_redirects=0` +
    `net.ipv4.conf.{all,default}.secure_redirects=0`;
    `net.ipv4.tcp_rfc1337=1`; `net.ipv4.tcp_fastopen=3`;
    `net.ipv4.tcp_congestion_control="bbr"` +
    `net.core.default_qdisc="fq"` (canonical BBR pairing — not cake);
    `boot.kernelModules += ["tcp_bbr"]` (list-merges with hardware files).
  - **Drop entirely.** `kernel.sysrq=0` (workstation REISUB escape hatch);
    `net.ipv4.conf.{all,default}.rp_filter=1` (would block G.1 Tailscale
    subnet routing — revisit only if G.1 lands and we explicitly want
    strict mode); `net.ipv4.tcp_syncookies=1` (mainline default);
    `security.rtkit.enable=true` (already set in
    `modules/services/sound/default.nix:3`);
    `security.sudo.wheelNeedsPassword=false` (per-host preference; t14g1 +
    virt use doas anyway).
  - **Hyprland stack.** Move
    `security.pam.services.hyprlock.text = "auth include login"` into
    `modules/desktop/hyprland-stack/default.nix`.
  - **Final step.** Delete `nixosModules/`.
- M.2 **Per-host README.** `modules/hosts/<host>/README.md` describing role,
  install steps, post-install checklist.
- M.3 **ADRs (architecture decision records).** `docs/decisions/000N-<topic>.md`
  for: dendritic adoption, flake-file adoption, neovim rewrite, etc.
- M.4 **Closure-size budgets.** `nix path-info -Sh` per host, alert on
  +N% growth.
- M.5 **Module-system unit tests.** `lib.evalModules` over feature modules
  with stub specialArgs; assert option types and defaults.
- M.6 **Colocate impermanence persistence to feature modules.** Each
  persisted directory currently requires two edits in the host file:
  one in `environment.persistence."/persist/system".directories` and
  one or more in `systemd.tmpfiles.rules` (with parent-dir rules for
  deep paths). T14g1's host file accumulates per-feature data —
  `/var/lib/tailscale` from the tailscale module, `/root/.ssh` from
  distributed-builds, `/etc/NetworkManager/system-connections` from
  NetworkManager — all leaking into the host's tmpfiles list. Two
  API options to weigh when picking up:
  - **M.6a (auto-derive tmpfiles).** Keep
    `environment.persistence."/persist/system".directories` as the
    source of truth; add a small `lib` helper that walks each entry
    (and its parents) and emits the corresponding tmpfiles rules.
    Kills the duplication without inventing new options. Per-feature
    data still accumulates in the host file's `directories` list,
    but each entry now lives on a single line. ~1-day refactor,
    eval-equivalent before/after.
  - **M.6b (per-feature persistence).** Each feature module that
    needs persistence declares it via a new option, e.g.
    `myNixosModules.impermanence.persistDirs = [ ... ];`. A central
    aggregator on impermanence-using hosts merges the lists into
    `environment.persistence` AND derives the tmpfiles rules.
    Self-contained feature modules — disabling tailscale removes
    its persistence automatically. Host file shrinks; new
    feature-with-persistence is a single declaration in the feature
    module. Larger refactor; introduces an option layer between
    feature modules and `environment.persistence`.
  - **Order.** M.6a is the cheaper precursor (replaces the tmpfiles
    list with derived rules); M.6b builds on it (moves the
    `directories` data from host to feature module, reusing the
    derivation logic). Could ship M.6a alone if M.6b feels
    invasive, or skip straight to M.6b once the API shape is
    decided.
  - **Proving ground.** T14g1 today (tailscale + distributed-builds
    - NetworkManager already declaring persistence). Cimmerian
      becomes a second host once A.1 lands; sartre never needs it
      (WSL has no concept of an ephemeral root).
- ~~M.7 **Treewide magic-string refactor onto `systemConstants`.**~~
  Centralised duplicated identity values onto the constants Aspect:
  `systemConstants.user` (was duplicated in
  `services/distributed-builds`, `flake/packages.nix`), new
  `systemConstants.repoPath` (was hard-coded as
  `/home/jmfv/nixos-dot` in `programs/nh` and the eight `nixd.expr`
  templates in `flake/packages.nix`), new `systemConstants.git.{name,
email}` (was hard-coded in `programs/git`). Also wired the HM
  class to import `systemConstants` via the `users/jmfv` module
  (was nominally promised in the constants module's docstring but
  never hooked up). Eval-verified equivalent across all 5 hosts +
  all 4 affected packages — drvPaths byte-identical before/after.
  README gained a "Forking / adopting" section walking through the
  knobs.
- ~~M.8 **Structural-rename swap-friendliness.**~~ Both layers
  decoupled:
  - **Per-host directory.** Each host file now derives
    `hostName = baseNameOf (toString ./.)` and uses
    `${hostName}` for the flake module key,
    `flake.nixosConfigurations` entry, `networking.hostName`,
    and the per-host registries (`flake.publicKeys`,
    `flake.hostIdentityKeys`). Renaming a host is now a single
    `git mv modules/hosts/<old> modules/hosts/<new>` plus
    swapping the SSH-key payloads.
  - **User-module identifier.** The user feature is registered
    under generic keys `flake.modules.{nixos,homeManager}.user`
    (was `.jmfv`). Inside `modules/users/jmfv/default.nix` the
    identity is read from `self.constants.user`, mirrored by
    `systemConstants.user`, so a single default edit (or override)
    moves the whole pipeline. The directory still happens to be
    named `jmfv` but is just a label — adopters can rename freely.
    Eval-verified across all 5 hosts + all 4 affected packages —
    drvPaths byte-identical before/after.

## N. Quality of life

- N.1 **xremap or kanata.** Cross-platform alternative to kmonad (which is
  Linux-only). Useful if sartre wants the same key remapping.
- N.2 **direnv everywhere.** Per-project `.envrc` with `use flake`.
- N.3 **sshfs / mounted remotes.** Quick filesystem access to other hosts.
- N.4 **HDR / VRR / fractional scaling.** Display tunings if hardware
  supports.
- N.5 **Cross-host clipboard sharing.** Yank-on-remote-ssh →
  paste-on-local should "just work". Two main paths:
  - **OSC 52 (recommended baseline).** Terminal escape sequence
    that lets a remote shell write into the local terminal's
    clipboard. Pure text, traverses SSH transparently, no daemons,
    no extra ports. Modern terminals (alacritty / kitty / foot /
    wezterm / ghostty), tmux, and nvim ≥0.10 all speak it. Setup
    is per-component: terminal usually opt-in, tmux
    `set -g set-clipboard on`, nvim `clipboard = "unnamedplus"`
    plus OSC 52 provider. Works across the wayland (t14g1) ↔ x11
    (cimmerian) split since the protocol is terminal-mediated.
    One-way (remote → local) by default; paste-into-remote is
    just typing into the terminal.
  - **lemonade / clipboard-relay-style TCP daemon.** Bidirectional;
    runs as a daemon on every host with an SSH port forward. More
    moving parts. Only worth it if OSC 52 falls short — large
    payloads, binary clipboards, or specific tooling that bypasses
    the terminal.
  - **Proving ground.** Test the t14g1 → cimmerian direction
    (sitting at t14g1's local terminal, ssh'd into cimmerian,
    yanking in nvim there → contents appear in t14g1's wayland
    clipboard via wl-clipboard). If that works through tmux too,
    it's done.
- N.6 **Upstream `programs.moonlight-qt` home-manager module.**
  Local stock-shape module lives at
  `packages/homeManager/moonlight-qt/` (enable + package +
  extraSettings, bash/awk merger that preserves `[hosts]` state
  and the embedded client private key). The dendritic wrapper at
  `modules/programs/moonlight-qt/` stays in this repo. Before
  opening a PR against `nix-community/home-manager`:
  - Audit option naming: `extraSettings` matches
    `programs.git.extraConfig`'s shape, but `settings` is the more
    recent HM convention. Pick one based on neighboring modules.
  - Polish the awk merger: brand-new-target case emits a leading
    blank line; keys appended to an existing section land after
    any in-section blank lines instead of before them. Both are
    cosmetic but worth tightening for upstream review.
  - Add a HM module test under `tests/modules/programs/moonlight-qt`
    that asserts the merged file contains both declared keys and a
    seeded `[hosts]` entry.
  - Document in HM's release notes; copy the description into the
    upstream option docs.
  - Open the PR; address review.

## O. Long-shot

- O.1 **Custom kernel feature via flake-file.** Per-host kernel patches.
  Only if hardware needs it.
- O.2 **nix-darwin host.** Only relevant if you get a Mac.
- O.3 **nixos-on-android (Termux + UserLAnd).** Extreme; for the meme.
