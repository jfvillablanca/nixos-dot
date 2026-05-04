# Neovim experimental rewrite

This document captures the design of `flake.packages.x86_64-linux.nvim-experimental`,
the in-progress rewrite of the neovim configuration toward portability and a
debloated plugin set built around stable native APIs (neovim 0.12).

The existing `flake.packages.x86_64-linux.nvim` (cimmerian's wrapped neovim,
re-exported by `modules/flake/packages.nix`) is the stable daily driver. It is
not touched by this rewrite. Every commit during the rewrite must keep
`.#nvim` byte- or NVD-equivalent against a baseline pinned at the start of
the work — see the stability gate section below.

## Goals

1. **`.#nvim-experimental` runs standalone on any nix-enabled machine.** No
   reliance on a host's NixOS or home-manager evaluation; no assumed XDG
   paths; no host-injected colorschemes, fonts, or external programs. The
   explicit foreign-host test target is WSL-Ubuntu (`sartre`).
2. **Every plugin is one dendritic module.** Adding/removing a plugin is a
   single-directory operation. Each plugin's source revision is a clearly
   labelled override knob, not buried inside `programs.neovim.plugins`.
3. **Debloat by leveraging stable native APIs.** Drop plugins whose
   functionality is now in nvim core (LSP setup, comment operator, snippet
   expansion). Smaller closure, fewer moving parts.
4. **Atomic, gated commits.** Each plugin port is its own commit; the
   stability gate is run after every commit to confirm `.#nvim` has not
   regressed.

## Non-goals (Phase 1)

- Project-aware lazy loading (e.g. only load Rust plugins inside a Rust
  project). Trigger metadata is captured in plugin modules from day one,
  but the lazy runner is Phase 2.
- Project-aware formatter/linter selection (detect `node_modules/.bin/eslint`
  vs system `eslint`). Phase 1 ports the current rigid none-ls config 1:1.
- "Minimal" / "full" build variants. The plumbing (`nvim.tools.*.enable`
  flags, gated optional plugins) is in place, but exposing distinct
  `flake.packages.x86_64-linux.nvim-experimental-{minimal,full}` is later.
- Promotion of `.#nvim-experimental` to `.#nvim`. That happens only when
  the experimental package is at parity, the user explicitly pulls the
  trigger, and host imports are migrated.

## Tree layout

```
modules/programs/neovim-experimental/
  default.nix                          # aggregator: collector + perSystem.packages.nvim-experimental
  _wrapper.nix                         # wrapNeovimUnstable callPackage helper (skipped by import-tree)
  _skeleton-options.nix                # top-level options module fed to lib.evalModules
  .luarc.json                          # lua-language-server workspace config

  core/
    options/{default.nix,_options.lua}       # vim.opt.* settings
    keymaps/{default.nix,_keymaps.lua}        # base keymaps (leader, etc)
    autocommands/{default.nix,_autocommands.lua}

  colorscheme/default.nix              # nvim.colorscheme top-level option (slug or null)

  lib/                                 # cross-cutting spines
    keymaps/default.nix                # nvim.keymaps : listOf submodule; emits _spine-keymaps.lua
    lsp-servers/default.nix            # nvim.lsp.servers : attrsOf submodule; emits _spine-lsp.lua
    treesitter/default.nix             # passive nvim-treesitter (Path B) + per-FileType vim.treesitter.start()
    statusline/default.nix             # nvim.statusline.components : listOf submodule (Phase 2 spine)
    formatters/default.nix             # nvim.formatters : attrsOf submodule (Phase 2 spine)
    dap/default.nix                    # nvim.dap.{adapters,configurations} (Phase 2 spine)

  plugins/
    <name>/{default.nix,_config.lua}   # one plugin per directory

  lsp/
    servers/<name>/default.nix         # one server per directory; contributes to nvim.lsp.servers
```

Conventions match the rest of the repo:

- Every feature is a directory with a `default.nix`.
- `_`-prefixed siblings are skipped by `vic/import-tree` (raw lua, helper
  Nix files, callPackage wrappers).
- Spines under `lib/` declare an `options.nvim.<concern>` and emit the
  synthesized lua file consumers source.

## The custom `nvim` flake-parts class

The Doc-Steve dendritic wiki explicitly endorses custom flake-module
classes ("nixvim", "nixOnDroid"). The experimental package introduces
class `nvim`:

- Each plugin / spine / core / lsp-server module declares
  `flake.modules.nvim.<name> = { ... }`.
- `modules/programs/neovim-experimental/default.nix` declares the
  collector: `flake.modules.nvim.default.imports = lib.attrValues
(lib.filterAttrs (n: _: n != "default") self.modules.nvim);`. Module-system
  merging composes the contributions automatically.
- The aggregator's `perSystem` runs `lib.evalModules` over
  `[ ./_skeleton-options.nix self.modules.nvim.default ]`, producing
  `eval.config.nvim.{plugins,extraPackages,extraLuaConfig,colorscheme}`,
  which feeds `pkgs.callPackage ./_wrapper.nix { ... }`.

Cross-class imports between `nvim` and `homeManager` / `nixos` are not
needed — the experimental package never goes through home-manager.

## Per-plugin module shape

Each plugin module:

1. Declares its own `enable` and `package` options under
   `nvim.plugins.<name>.{enable,package}`. The `package` option is the
   override knob — swap it to an upstream HEAD outpath at any consumer
   site (host import, factory call, manual override) without re-fitting.
2. Contributes its plugin spec to the shared `nvim.plugins.list` option.
3. Contributes to relevant spines (`nvim.keymaps`, `nvim.lsp.servers`, etc).
4. Captures lazy-load triggers as data, even if Phase 1 ignores them.
5. Sources its lua config via `builtins.readFile ./_config.lua` so the
   lua stays editable in nvim with stylua/lua-language-server tooling.

```nix
# modules/programs/neovim-experimental/plugins/gitsigns/default.nix
{lib, ...}: {
  flake.modules.nvim.gitsigns = {
    config,
    pkgs,
    ...
  }: {
    options.nvim.plugins.gitsigns = {
      enable = lib.mkEnableOption "gitsigns" // {default = true;};
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vimPlugins.gitsigns-nvim;
        description = "gitsigns source. Override to swap nixpkgs's pinned rev for upstream HEAD.";
      };
    };

    config = lib.mkIf config.nvim.plugins.gitsigns.enable {
      nvim.plugins.list = [
        {
          plugin = config.nvim.plugins.gitsigns.package;
          type = "lua";
          config = builtins.readFile ./_config.lua;
          lazy.event = ["BufReadPre" "BufNewFile"];
        }
      ];
      nvim.keymaps = [
        {mode = "n"; lhs = "]c"; rhs = "<cmd>Gitsigns next_hunk<cr>"; desc = "Next git hunk"; group = "git";}
        {mode = "n"; lhs = "[c"; rhs = "<cmd>Gitsigns prev_hunk<cr>"; desc = "Prev git hunk"; group = "git";}
      ];
    };
  };
}
```

`_config.lua` is the plain lua setup the plugin needs at runtime, with
LuaCATS type annotations:

```lua
---@type fun(opts: Gitsigns.Config)
require("gitsigns").setup({
  signs = { ... },
})
```

## Cross-cutting concerns: spines

Some plugins coordinate across the config (which-key reads everyone's
keymaps; lualine reads everyone's statusline components; cmp-nvim-lsp
exposes capabilities to every LSP server). A monolithic plugin file
embeds these dependencies; the spine pattern inverts them.

A spine is a one-file feature module under `lib/<spine>/default.nix`
that declares a typed option. Plugins contribute to the option; one
consumer module reads the merged result and emits the corresponding
lua. The module system handles merging.

```nix
# modules/programs/neovim-experimental/lib/keymaps/default.nix
{lib, ...}: {
  flake.modules.nvim.lib-keymaps = {config, ...}: {
    options.nvim.keymaps = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          mode = lib.mkOption { type = with lib.types; either str (listOf str); default = "n"; };
          lhs = lib.mkOption { type = lib.types.str; };
          rhs = lib.mkOption { type = with lib.types; either str lines; };
          desc = lib.mkOption { type = lib.types.str; };
          group = lib.mkOption { type = with lib.types; nullOr str; default = null; };
        };
      });
      default = [];
      description = "Cross-cutting keymap registry. Plugins contribute; which-key consumes.";
    };

    config.nvim.spineLua.keymaps = ''
      ---@type vim.api.keyset.keymap
      local function set(km)
        vim.keymap.set(km.mode, km.lhs, km.rhs, { desc = km.desc })
      end
      ${lib.concatMapStringsSep "\n" (km: "set(${builtins.toJSON km})") config.nvim.keymaps}
    '';
  };
}
```

Spines emit synthesized lua via `nvim.spineLua.<name>` (a stringly-typed
attrset the wrapper writes out as `_spine-<name>.lua` files in the
runtimepath) rather than appending to `extraLuaConfig`. This makes the
generated code debuggable — you can `:edit $VIMRUNTIME/lua/_spine-keymaps.lua`
and read what the build produced.

### Spines in use

| Spine        | Option                                          | Consumer                                                                                                                  |
| ------------ | ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| keymaps      | `nvim.keymaps`                                  | `vim.keymap.set` per entry; which-key auto-discovers descs                                                                |
| lsp-servers  | `nvim.lsp.servers`                              | `vim.lsp.config` + `vim.lsp.enable` (native, 0.11+)                                                                       |
| lsp-attach   | `nvim.lsp.{formatProviderDisable,formatOnSave}` | `LspAttach` autocmd: per-buffer keymaps (K/gd/gD/gI/gr/`<leader>l*`), diagnostic config, hover/sig border, format-on-save |
| treesitter   | (passive)                                       | per-FileType `vim.treesitter.start()` autocmd                                                                             |
| env-finalize | (none — `nvim.spineLua.zzz_env_finalize`)       | runs last; honors `NVIM_TRUECOLOR` + `NVIM_LOCAL_INIT`                                                                    |

`lib/env-bootstrap/` is not a spine — it contributes to `nvim.extraLuaConfig`
with `lib.mkOrder 100` so it runs before core options and per-plugin configs,
populating `_G.NVIM_DISABLED` for `_G.nvim_disabled("<name>")` checks.

### Spines deferred (no current contributor)

| Spine       | Option                               | Consumer  |
| ----------- | ------------------------------------ | --------- |
| statusline  | `nvim.statusline.components`         | lualine   |
| cmp-sources | `nvim.cmp.sources`                   | blink.cmp |
| formatters  | `nvim.formatters`                    | none-ls   |
| linters     | `nvim.linters`                       | none-ls   |
| dap         | `nvim.dap.{adapters,configurations}` | nvim-dap  |

These plugins ship with their config inline today; spines get added when a
contributor needs them.

## Treesitter strategy (Path B: passive parser asset)

`nvim-treesitter` (master, archived) is kept in the runtimepath as a
parser+query asset only — its `setup()` is **not** called for
`highlight = { enable = true }`. Instead, an autocmd starts treesitter
per buffer:

```lua
---@param args { buf: integer, match: string }
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})
```

`nvim-treesitter-textobjects` and `nvim-treesitter-context` plug into
`nvim-treesitter.configs.setup{}` for their respective subsystems, so
`setup()` is still called — but only with `textobjects = {...}` and
nothing else. Highlight remains native.

This Path B keeps text-object selection (`vif`/`vaf`/`vac`) and the
sticky function-header context window working, at the cost of one
plugin (`nvim-treesitter` itself) sitting in the rtp as a passive
library. Trade-off accepted in design discussion.

## Override knobs

The per-plugin `nvim.plugins.<name>.package` is the primary knob. Override
flavors:

1. **nixpkgs default (no work)** — `package = pkgs.vimPlugins.<name>`.
2. **Per-plugin upstream input via flake-file.** Each plugin module
   colocates its own flake input + builds from upstream HEAD. Canonical
   shape (`plugins/oil/default.nix`):

   ```nix
   {lib, ...}: {
     flake-file.inputs.plugin-oil-nvim = {
       url = "github:stevearc/oil.nvim";
       flake = false;
     };
     flake.modules.nvim.oil = {config, inputs, pkgs, ...}: {
       options.nvim.plugins.oil.package = lib.mkOption {
         type = lib.types.package;
         default = pkgs.vimUtils.buildVimPlugin {
           pname = "oil-nvim";
           version = "upstream-${inputs.plugin-oil-nvim.shortRev or "head"}";
           src = inputs.plugin-oil-nvim;
         };
       };
       # ...
     };
   }
   ```

   Workflow: edit module → `nix run .#write-flake` → `nix flake lock`
   (or `nix flake update plugin-oil-nvim` later) → commit `flake.nix`
   - `flake.lock` + module together. `nix flake check` fails if
     `flake.nix` is stale w.r.t. the module declarations.

3. **Bulk upstream pins via overlay** — a `_overlay.nix` under the
   experimental tree that swaps multiple `pkgs.vimPlugins.*` entries.
   Reserved for "we're tracking many plugins ahead of nixpkgs."

Mantra: **as many flake inputs as necessary to keep things stable.**
If a plugin is broken when built from nixpkgs's pinned rev, add an
upstream-pinned input via flake-file.

## The two-input neovim strategy

`flake.nix` has two neovim-nightly-overlay inputs:

- `inputs.neovim-nightly-overlay` — consumed by `mkNixos` for `.#nvim`
  (cimmerian's daily driver).
- `inputs.neovim-nightly-overlay-experimental` — consumed by the
  experimental package's `perSystem` only.

Each is independently advanced via `nix flake update <input>`. Bumping
the experimental overlay never moves cimmerian's neovim; bumping the
stable overlay never moves the experimental neovim. The experimental
overlay is pinned to a 0.12-stable rev for now.

## Stability gate

The single most important invariant during the rewrite: **`.#nvim` does
not regress**. Mechanism:

```fish
just nvim-baseline   # run once at the start of the rewrite branch
just nvim-gate       # run after every commit
```

`nvim-baseline` captures `nix build .#nvim --no-link --print-out-paths`
into `.nvim-baseline.path` (gitignored).

`nvim-gate` rebuilds `.#nvim` and either reports "byte-equal: ok" or
runs `nvd diff` against the baseline. Acceptable result: "No version
or selection state changes." Anything else is a regression. Module-eval
ordering can cause harmless hash drift, so byte-equality is not the
bar — NVD-equivalence is.

This is the same pattern documented in `docs/ARCHITECTURE.md` for
cimmerian's NixOS system.

## `nix run .#nvim-experimental` smoke test

```fish
just nvim-exp-smoke   # nix run .#nvim-experimental -- --headless +'lua print("ok")' +q
```

Phase 1 verifies on cimmerian only. Foreign-host (sartre, WSL Ubuntu)
verification comes when the experimental package reaches feature
parity.

## Plugin sweep verdict (Phase 1)

Going through `modules/programs/neovim/default.nix` active plugins:

| Plugin                                                                        | Verdict            | Reasoning                                                               |
| ----------------------------------------------------------------------------- | ------------------ | ----------------------------------------------------------------------- |
| `nvim-tree-lua`                                                               | drop               | redundant with oil.nvim                                                 |
| `oil-nvim`                                                                    | keep               | primary file nav                                                        |
| `lualine-nvim`                                                                | keep               | no native statusline alternative; `nvim.statusline.components` consumer |
| `indent-blankline-nvim`                                                       | keep               | richer than native `listchars`                                          |
| `nvim-autopairs`                                                              | keep               | no native equivalent                                                    |
| `nvim-surround`                                                               | keep               | core text manipulation                                                  |
| `treesj`                                                                      | keep               | split/join                                                              |
| `which-key-nvim`                                                              | keep               | repurposed as `nvim.keymaps` consumer                                   |
| `nvim-cmp` + 6 cmp sources + `cmp_luasnip`                                    | swap → blink.cmp   | seven plugins → one                                                     |
| `luasnip` + `friendly-snippets`                                               | drop               | snippets unused; blink.cmp has `vim.snippet` if needed                  |
| `neogen`                                                                      | drop               | unused                                                                  |
| `copilot-vim`                                                                 | swap → copilot.lua | better lua ecosystem fit                                                |
| `codecompanion-nvim`, `CopilotChat-nvim`                                      | drop               | unused                                                                  |
| `nvim-lspconfig`                                                              | drop               | replaced by `vim.lsp.config()` + `vim.lsp.enable()` (0.11+)             |
| `nvim-vtsls`                                                                  | keep               | VTSLS-specific glue (organize imports, etc)                             |
| `go-nvim`                                                                     | keep               | Go UX, lazy on `FileType go`                                            |
| `rustaceanvim`                                                                | keep               | replaces lspconfig for rust-analyzer                                    |
| `refactoring-nvim`                                                            | keep               | no native alternative                                                   |
| `nvim-dap`                                                                    | keep, gated        | `nvim.tools.debug.enable = false` default                               |
| `none-ls-nvim`                                                                | keep               | port current rigid config; project-aware deferred                       |
| `telescope-nvim`                                                              | keep               | extensively used                                                        |
| `nvim-treesitter.withAllGrammars`                                             | demote (Path B)    | passive parser asset; no `setup()` for highlight                        |
| `nvim-treesitter-textobjects`                                                 | keep               | uses TS queries via Path B                                              |
| `nvim-treesitter-context`                                                     | keep               | small; sticky function header                                           |
| `gitsigns-nvim`                                                               | keep               | spine contributor (keymaps + statusline)                                |
| `vim-fugitive`                                                                | keep               | irreplaceable                                                           |
| `octo-nvim`                                                                   | drop               | unused                                                                  |
| `comment-nvim`                                                                | drop               | native `gc`/`gcc` (0.10+)                                               |
| `nvim-ts-context-commentstring`                                               | drop               | embedded language comments out of scope                                 |
| `nvim-ts-autotag`                                                             | keep               | HTML/JSX autoclose                                                      |
| `nvim-web-devicons`                                                           | keep               | active upstream                                                         |
| `trouble-nvim`                                                                | keep               | diagnostics + LSP refs UI                                               |
| `todo-comments-nvim`                                                          | keep               | small                                                                   |
| `flash-nvim`                                                                  | keep               | superset of leap                                                        |
| `markdown-preview-nvim`                                                       | keep, gated        | `nvim.tools.markdown-preview.enable = false` default                    |
| `nvim-highlight-colors`                                                       | keep               | hex highlighter                                                         |
| `vimtex`                                                                      | drop               | native LSP (texlab) handles tex                                         |
| `cellular-automaton-nvim`                                                     | keep               | fun, ~tens of KB                                                        |
| Colorschemes (`gruvbox`, `tokyonight`, `catppuccin`, `rose-pine`, `kanagawa`) | drop all           | top-level `nvim.colorscheme` option                                     |
| `base16-nvim`                                                                 | keep, gated        | only when nix-colors slug passed; otherwise dropped                     |

Net: ~50 active plugins → ~28 + blink.cmp + copilot.lua = **~30 plugins**.
40% reduction.

## Lua type annotations

All authored lua under the experimental tree uses LuaCATS annotations
(`---@type`, `---@class`, `---@param`). `modules/programs/neovim-experimental/.luarc.json`
points lua-language-server at the wrapped neovim's runtime types and
the bundled plugin tree's lua so editing any `_config.lua` or
`_options.lua` gives autocomplete and type checks.

Spine-emitted `_spine-<name>.lua` files include their own LuaCATS
annotations so generated code is self-documenting.

## Phased rollout

**Phase 1 — pipeline proven end-to-end. Done.**

Aggregator skeleton (`default.nix` + `_wrapper.nix` +
`_skeleton-options.nix` + `.luarc.json`) wraps `neovim-unwrapped` via
`wrapNeovimUnstable`. Stability gate (`just nvim-baseline` /
`just nvim-gate`) was set up against cimmerian's daily-driver baseline.
Spines — keymaps, lsp-servers, treesitter (Path B passive). Core config
ported (options, keymaps, autocommands). Three representative plugins
proved Simple Aspect + spine-contributor + spine-consumer patterns
(oil, gitsigns, telescope). lua-ls server module exercised the
lsp-servers spine.

**Phase 2 — bulk plugin port. Done.**

Every plugin from the original `modules/programs/neovim/default.nix`
sweep verdict ported as its own commit. Remaining ports landed in
audit closeout (see below). Daily-driver gate stayed byte-equal
throughout. Caveat: a stretch of commits in Phase 2 didn't build
`.#nvim-experimental` cleanly because the gate only watches `.#nvim`;
the working overlay fix landed in `d81f182`. See git log around
`4e98912..d81f182`.

**Phase 3 — portability hardening (foreign hosts). Done.**

Four env-var overrides for foreign-host runs. Plumbing lives in
`lib/env-bootstrap/` (runs before per-plugin configs) and
`lib/env-finalize/` (runs after, as a spine). Colorscheme override is
inline in `_wrapper.nix`'s `customRC`.

| env var            | effect                                                                            | implementation           |
| ------------------ | --------------------------------------------------------------------------------- | ------------------------ |
| `NVIM_DISABLE`     | comma-separated plugin skip list; plugins opt in via `_G.nvim_disabled("<name>")` | `lib/env-bootstrap/`     |
| `NVIM_TRUECOLOR=0` | clear `termguicolors` for capability-poor terminals                               | `lib/env-finalize/`      |
| `NVIM_COLORSCHEME` | override the build-time baked colorscheme                                         | inline in `_wrapper.nix` |
| `NVIM_LOCAL_INIT`  | source per-machine init last; default `~/.config/nvim-local/init.lua`             | `lib/env-finalize/`      |

Plugins opt into the disable gate by adding a one-liner at the top of
their `_config.lua`:

```lua
if _G.nvim_disabled and _G.nvim_disabled("copilot") then
  return
end
```

Currently only `copilot.lua` opts in (the canonical foreign-host case
since copilot needs GitHub auth). Add the same pattern to other
plugins as portability cases come up.

Smoke-test recipes (run on cimmerian for parity, then on sartre):

```fish
# Default run: all plugins active, baked colorscheme.
nix run github:jfvillablanca/nixos-dot#nvim-experimental

# Foreign-host run: skip copilot, force-disable truecolor.
NVIM_TRUECOLOR=0 NVIM_DISABLE=copilot \
  nix run github:jfvillablanca/nixos-dot#nvim-experimental

# Custom colorscheme + per-machine init.
NVIM_COLORSCHEME=desert NVIM_LOCAL_INIT=~/dotnvim/init.lua \
  nix run github:jfvillablanca/nixos-dot#nvim-experimental

# Headless verification.
nix run github:jfvillablanca/nixos-dot#nvim-experimental -- \
  --headless +'lua print("smoke: ok")' +q
```

extraPackages were audited and contain only nix-store paths — no
host-specific assumptions. Each plugin pulls the runtime tools it
needs (telescope → ripgrep, none-ls → its formatter set, copilot.lua
→ withNodeJs). LSP servers contribute their packages via the
`lsp-servers` spine.

**Phase 4 — factory + host imports. Done.**

`flake.factory.nvim` (declared in `modules/programs/neovim-experimental/factory/`)
is a Factory Aspect that produces a wrapped nvim derivation parameterized
by host preferences. Same Factory pattern as `flake.factory.user`.

```nix
flake.factory.nvim = {
  system,                         # required
  colorscheme ? null,             # full colorscheme name (e.g. "base16-spaceduck")
  base16 ? false,                 # include base16-nvim in the closure
  debugEnable ? false,            # nvim.tools.debug.enable
  markdownPreviewEnable ? false,  # nvim.tools.markdown-preview.enable
  extraOverlays ? [],             # additional pkgs overlays
  extraModules ? [],              # additional module-system overrides
}: <wrapped nvim derivation>;
```

Per-host packages call the factory with their preferences from
`modules/flake/packages.nix`:

| Package                         | Variant                                                      |
| ------------------------------- | ------------------------------------------------------------ |
| `.#nvim-experimental`           | standalone, no host inference                                |
| `.#nvim-experimental-cimmerian` | `base16-spaceduck` + debug + md-preview + eslint/texlab LSPs |
| `.#nvim-experimental-t14g1`     | `base16-gruvbox-dark-hard` + same tool gates                 |

Convenience targets in `justfile`:

```fish
just nvim-exp             # standalone
just nvim-exp-cimmerian   # cimmerian-flavored
just nvim-exp-t14g1       # t14g1-flavored
```

`.#nvim` (cimmerian's daily driver via the home-manager eval) is
unaffected by Phase 4 — adding flake-package outputs doesn't touch
cimmerian's NixOS closure. NVD-gate stays byte-equal.

## Audit and closeout (between Phase 4 and Phase 5)

A full audit ran before promotion. Goals 1, 3, 4 hit cleanly. Goal 2
(override knob) was structurally present but never exercised
end-to-end. Daily-driver feature parity had real gaps.

Closeout fixes landed:

| Gap                                                                                                      | Fix                                                                                                                                                                                                                |
| -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| LSP attach behavior absent (no nav keymaps, no format-on-save, no diagnostic config)                     | `lib/lsp-attach/` spine: LspAttach autocmd, K/gd/gD/gI/gr/`<leader>l*` keymaps, format-on-save filtered to null-ls, hover/sig border, per-server formatter disable list                                            |
| Buffer/window keymaps `<leader>{w,q,c,d}` missing                                                        | Added to `core/keymaps/_keymaps.lua` under "User shortcuts" section                                                                                                                                                |
| Telescope `<leader>t*` muscle memory broken                                                              | `plugins/telescope/`: restored `<leader>t{f,h,b,c,C,R,k,o,r,w}` + `<leader>/` + `<leader><space>`                                                                                                                  |
| Missing LSP servers (nixd, pylsp, ccls)                                                                  | Per-server modules under `lsp/servers/`. nixd default-on (cimmerian/t14g1 wire NixOS options expansion via factory `extraModules`); pylsp/ccls default-off. nil_ls/prismals/purescriptls explicitly dropped        |
| Override knob (Goal 2) never exercised                                                                   | Adopted vic/flake-file for decentralized input declarations. oil-nvim is the proof-of-life — declares `flake-file.inputs.plugin-oil-nvim` from within its own module and builds via `pkgs.vimUtils.buildVimPlugin` |
| Per-server formatter clash with none-ls                                                                  | `lua-ls`, `vtsls`, `nixd`, `pylsp` modules each contribute their server name to `nvim.lsp.formatProviderDisable`                                                                                                   |
| Misc keymap parity (`<leader>g{n,t}` diffget, `<leader>fm{l,g,s}` fun, `<leader>h{u,R}` gitsigns extras) | Filled in across `vim-fugitive`, `cellular-automaton`, `gitsigns` modules                                                                                                                                          |

**Findings the user explicitly accepted as wontfix:**

- **Closure size larger than `.#nvim`** (3.6 GiB vs 3.2 GiB). The
  experimental package bakes language toolchains and LSP servers into
  the closure (gopls, rust-analyzer, clang-tools, lua-language-server,
  formatter set). The original daily driver picks these up from
  cimmerian's system-level packages on `$PATH`. Accepted for
  portability symmetry across hosts.
- Some Phase 2 commits don't build `.#nvim-experimental` individually —
  bisect-hostile but doesn't affect daily driver. Not worth a rebase.

## Phase 5 — promotion (planned)

Trial period first: the user daily-drives `.#nvim-experimental-cimmerian`
for ~1 week before promotion. Issues found during the trial get
filed/fixed in the experimental tree without touching `.#nvim`.

### Pre-promotion checklist

Future session before promoting should re-verify:

1. `just nvim-gate` byte-equal to baseline.
2. `nix run .#nvim-experimental-cimmerian` smoke (open nvim, hit
   `<leader>ff`, `K` on a symbol, save a `.lua` file, confirm format).
3. cimmerian-only LSP servers attach (`bashls`, `lua_ls`, `nixd`,
   `vtsls`, `tailwindcss`, `html/css/json`, `eslint`, `texlab`).
4. None-ls formatters work end-to-end (stylua, alejandra, black, etc.).
5. Sartre (WSL) smoke test — confirm `nix run .#nvim-experimental` with
   `NVIM_DISABLE=copilot NVIM_TRUECOLOR=0` if needed.
6. No new daily-driver muscle-memory gaps the user noticed during trial.

### Promotion steps

1. Capture cimmerian's NixOS baseline:
   `nix build .#nixosConfigurations.cimmerian.config.system.build.toplevel`.
2. In cimmerian's `_home.nix`, replace
   `inputs.self.modules.homeManager.neovim` import with the equivalent
   that consumes `flake.factory.nvim {...}` (set `programs.neovim.package`
   directly or via a thin home-manager module).
3. Re-build; NVD-diff vs baseline. Acceptable: version changes for the
   neovim plugin set + extraPackages (expected; new closure shape).
4. Switch `flake.packages.x86_64-linux.nvim` in
   `modules/flake/packages.nix` to re-export the cimmerian-flavored
   experimental output (or drop the alias if redundant with
   `nvim-experimental-cimmerian`).
5. Remove `modules/programs/neovim/` (the old tree).
6. Pin a NEW baseline for `.#nvim` (it's now the experimental closure)
   so future audits gate against it.
7. Update memory + this doc to reflect promoted state.

## Remaining future work

- **Project-aware lazy loading.** Plugin modules already declare
  `lazy.event` / `lazy.cmd` / `lazy.ft` triggers; the lazy runner
  swaps `extraLuaConfig` for `opt = true` plugins + a small loader
  that reads the triggers and `packadd`s on FileType.
- **Project-aware formatters/linters.** none-ls's `condition` callbacks
  enable per-project tool selection. Wire via the formatters/linters
  spines (currently deferred — none-ls is configured rigidly).
- **Build variants.** `nvim-experimental-minimal` (no markdown-preview,
  no debug, no AI) and `nvim-experimental-full`. Two collectors
  importing different subsets via the factory.
- **More upstream pins via flake-file.** Pattern is proven for oil; add
  more as plugins drift from nixpkgs's pinned revs.
- **Foreign-host extras.** copilot is the only plugin that opts into
  `_G.nvim_disabled("...")` today. Add to other auth-needing or
  network-using plugins when a real foreign-host case shows up.
