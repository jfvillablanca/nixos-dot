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

## D. Secrets ★

- D.1 **sops-nix.** age key per host, encrypted yamls in `secrets/`. Migrate
  cachix token, copilot auth, github tokens, ssh keys, wifi credentials.
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
- F.6 **Lockfile flatten.** flake-file ships `allfollow` + `prune-lock`
  modules — adopt to shrink lock duplications.

## G. Networking

- G.1 **Tailscale or wireguard mesh.** Cimmerian + t14g1 + sartre on the
  same overlay. Easier ssh, file transfer, distributed builds.
- G.2 **SSH config consolidation.** Per-host `programs.ssh.matchBlocks`,
  shared `known_hosts`.
- G.3 **Distributed builds.** Cimmerian as remote builder for t14g1
  (workstation has more cores).

## H. Self-hosted (optional)

- H.1 **atticd or harmonia.** Local nix binary cache. Reduces cachix
  dependency for personal infra.
- H.2 **vaultwarden / nextcloud.** If cimmerian is up reliably.
- H.3 **gitea / forgejo.** Private repo mirror.

## I. Dev environment

- I.1 ★ **Replace `use` with `comma` + `nix-index-database`.** Drop
  `packages/by-name/u/use/`. comma resolves by binary name (`, convert`
  → imagemagick) via prebuilt nix-index DB; the existing `use` script
  needs the attribute name. Module: import
  `inputs.nix-index-database.nixosModules.nix-index` + add `comma` to
  user packages.
- I.2 ★ **nh (nixos-helper).** Ergonomic rebuilds (`nh os switch`, `nh home
switch`). Replaces raw `nixos-rebuild` / `home-manager` calls.
- I.3 ★ **nix-output-monitor (nom).** Replaces the default build progress
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

- J.1 **flake-parts options.** No completion on `perSystem.<tab>` or
  `flake.modules.<class>.<name>`. Add `debug.enable = true;` somewhere
  under `modules/flake/` to expose the flake-parts option tree at
  `outputs.debug.options`, then point `nixd`'s `options.flake_parts.expr`
  at it.
- J.2 **Factory args.** No completion when editing the experimental factory
  call site. Expose `flake.lib.nvimOptions = eval.options` from the
  experimental aggregator (`modules/programs/neovim-experimental/factory/`)
  and add a matching `nixd.options.<name>.expr` entry.
- J.3 **flake-file options.** No completion on `flake-file.inputs.<tab>`.
  Same shape: expose flake-file's evaluated options, point an `expr`
  at it.

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
- L.4 **flake-schemas** (DeterminateSystems). Makes `nix flake show`
  introspect `flake.modules.nvim.*` + `flake.factory.*` properly.

## M. Repo hygiene

- M.1 **`nixosModules/` draft.** Long-untracked. Decide: graduate into the
  dendritic tree, or delete.
- M.2 **Per-host README.** `modules/hosts/<host>/README.md` describing role,
  install steps, post-install checklist.
- M.3 **ADRs (architecture decision records).** `docs/decisions/000N-<topic>.md`
  for: dendritic adoption, flake-file adoption, neovim rewrite, etc.
- M.4 **Closure-size budgets.** `nix path-info -Sh` per host, alert on
  +N% growth.
- M.5 **Module-system unit tests.** `lib.evalModules` over feature modules
  with stub specialArgs; assert option types and defaults.

## N. Quality of life

- N.1 **xremap or kanata.** Cross-platform alternative to kmonad (which is
  Linux-only). Useful if sartre wants the same key remapping.
- N.2 **direnv everywhere.** Per-project `.envrc` with `use flake`.
- N.3 **sshfs / mounted remotes.** Quick filesystem access to other hosts.
- N.4 **HDR / VRR / fractional scaling.** Display tunings if hardware
  supports.

## O. Long-shot

- O.1 **Custom kernel feature via flake-file.** Per-host kernel patches.
  Only if hardware needs it.
- O.2 **nix-darwin host.** Only relevant if you get a Mac.
- O.3 **nixos-on-android (Termux + UserLAnd).** Extreme; for the meme.
