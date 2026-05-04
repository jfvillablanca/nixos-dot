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

### Spines in Phase 1

| Spine       | Option             | Consumer                                            | Status  |
| ----------- | ------------------ | --------------------------------------------------- | ------- |
| keymaps     | `nvim.keymaps`     | which-key (Phase 2) + `vim.keymap.set` (Phase 1)    | Phase 1 |
| lsp-servers | `nvim.lsp.servers` | `vim.lsp.config` + `vim.lsp.enable` (native, 0.11+) | Phase 1 |
| treesitter  | (passive)          | per-FileType `vim.treesitter.start()` autocmd       | Phase 1 |

### Spines in Phase 2

| Spine       | Option                               | Consumer  |
| ----------- | ------------------------------------ | --------- |
| statusline  | `nvim.statusline.components`         | lualine   |
| cmp-sources | `nvim.cmp.sources`                   | blink.cmp |
| formatters  | `nvim.formatters`                    | none-ls   |
| linters     | `nvim.linters`                       | none-ls   |
| dap         | `nvim.dap.{adapters,configurations}` | nvim-dap  |

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

The per-plugin `nvim.plugins.<name>.package` is the primary knob. Three
override flavors:

1. **nixpkgs default (no work)** — `package = pkgs.vimPlugins.<name>`.
2. **Per-plugin upstream input** — for a single plugin that's broken
   in nixpkgs, add a flake input pinned to the upstream rev:
   ```nix
   # flake.nix
   inputs.upstream-oil = { url = "github:stevearc/oil.nvim"; flake = false; };
   ```
   ```nix
   # plugins/oil/default.nix consumer-side override
   nvim.plugins.oil.package = pkgs.vimUtils.buildVimPlugin {
     pname = "oil-nvim"; version = "upstream";
     src = inputs.upstream-oil;
   };
   ```
3. **Bulk upstream pins via overlay** — a `_overlay.nix` under the
   experimental tree that swaps multiple `pkgs.vimPlugins.*` entries.
   Reserved for "we're tracking many plugins ahead of nixpkgs."

The mantra: **as many flake inputs as necessary to keep things stable.**
If a plugin is broken when built from nixpkgs's pinned rev, add an
input from a rev that ships a stable or patched version.

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

**Phase 1 — pipeline proven end-to-end.**

1. Design doc (this file).
2. Second pinned `neovim-nightly-overlay-experimental` flake input.
3. Just-driven stability gate (`just nvim-baseline`, `just nvim-gate`,
   `just nvim-exp-smoke`); `pkgs.just` in the dev shell.
4. Aggregator skeleton: `default.nix` + `_wrapper.nix` +
   `_skeleton-options.nix` + `.luarc.json`. Builds an empty wrapped
   neovim.
5. Spines: keymaps, lsp-servers, treesitter (Path B passive).
6. Core config: options, keymaps, autocommands.
7. Colorscheme option module (no plugin until base16-nvim is wired in
   for slug consumers).
8. Three representative plugins: oil (Simple Aspect), gitsigns
   (spine contributor), telescope (spine consumer for extensions).
9. One LSP server module (lua-ls) to exercise the lsp-servers spine.

After Phase 1: `nix run .#nvim-experimental` produces a runnable nvim
with three plugins and one configured LSP server. The pipeline is
proven; subsequent commits are bulk plugin ports.

**Phase 2 — bulk plugin port.**

One commit per plugin module, in this order:

1. Trivially-config'd: oil (already), nvim-autopairs, nvim-surround,
   treesj, indent-blankline-nvim, flash-nvim, todo-comments-nvim,
   nvim-highlight-colors, cellular-automaton-nvim, nvim-ts-autotag,
   nvim-web-devicons, vim-fugitive, refactoring-nvim, trouble-nvim.
2. Spine-heavy: which-key (consumer), gitsigns (already), lualine
   (statusline spine), blink.cmp (cmp-sources spine).
3. LSP servers: bash-language-server, vtsls, tailwindcss, html/css/json
   (vscode-langservers-extracted), texlab.
4. Language-specific: nvim-vtsls, go-nvim (lazy), rustaceanvim (lazy).
5. Big config: telescope (already), nvim-treesitter passive +
   textobjects + context, none-ls.
6. Optional / gated: nvim-dap (`tools.debug`), markdown-preview
   (`tools.markdown-preview`), copilot.lua, base16-nvim (slug-gated).

After every plugin commit: `just nvim-gate` confirms `.#nvim` is
unchanged.

**Phase 3 — portability hardening (foreign hosts).**

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

**Phase 4 — factory + host imports.**

1. Expose `flake.factory.nvim` taking `{ colorscheme, tools, plugins.disabled, pkgs }`.
2. Hosts (cimmerian, t14g1) import the factory, pass their preferences
   (e.g. `colorscheme = "spaceduck"` from stylix slug).
3. NVD-gate cimmerian to confirm closure equivalence.

**Phase 5 — promotion.**

When the user pulls the trigger: `flake.packages.x86_64-linux.nvim`
re-points at `nvim-experimental` (or the factory call cimmerian uses).
Old `modules/programs/neovim/` is removed.

## Future work (Phase 2+)

- **Project-aware lazy loading.** Plugin modules already declare
  `lazy.event` / `lazy.cmd` / `lazy.ft` triggers; the lazy runner
  swaps `extraLuaConfig` for `opt = true` plugins + a small loader
  that reads the triggers and `packadd`s on FileType.
- **Project-aware formatters/linters.** none-ls's `condition` callbacks
  enable per-project tool selection. Wire via the formatters/linters
  spines.
- **Build variants.** `nvim-experimental-minimal` (no markdown-preview,
  no debug, no AI) and `nvim-experimental-full`. Two collectors
  importing different subsets.
- **flake-file adoption.** When the per-plugin upstream-input list
  grows past a handful, migrate `inputs` declarations into per-plugin
  feature modules via vic/flake-file.
