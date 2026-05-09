# Treesitter spine — Path B "passive parser asset".
#
# nvim-treesitter (master, archived) sits in rtp as the source of parsers +
# queries; we do NOT call its `setup{ highlight = { enable = true } }`.
# Highlight is started natively per FileType via `vim.treesitter.start()`.
#
# textobjects + context (Phase 2) plug into nvim-treesitter.configs.setup{}
# for their respective subsystems and continue to work since the plugin is
# in the runtimepath.
_: {
  flake.modules.nvim.lib-treesitter = {
    config,
    pkgs,
    lib,
    ...
  }: {
    options.nvim.treesitter.package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
      description = ''
        Treesitter parser+query asset. Override to swap nixpkgs's pinned
        rev or to use a custom grammar bundle. Sits in rtp passively;
        highlight is `vim.treesitter.start()`, not `setup{}`.
      '';
    };

    config = {
      nvim.plugins.list = [
        {plugin = config.nvim.treesitter.package;}
      ];

      nvim.spineLua.treesitter = ''
        -- _spine_treesitter.lua: synthesized.
        -- See modules/programs/neovim-experimental/lib/treesitter/default.nix.
        -- Path B: nvim-treesitter is a passive parser+query asset; highlight
        -- starts natively per FileType.

        vim.api.nvim_create_autocmd("FileType", {
          group = vim.api.nvim_create_augroup("NvimSpineTreesitter", { clear = true }),
          ---@param args { buf: integer, match: string }
          callback = function(args)
            -- pcall: parsers may be absent for some filetypes (e.g. plain text).
            local ok = pcall(vim.treesitter.start, args.buf)
            if ok then
              vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
              vim.wo[0][0].foldmethod = "expr"
            end
          end,
        })

        -- Match-format compat patch for archived nvim-treesitter master.
        --
        -- nvim a728eb7 (Mar 2026, ~v0.12.0~53) removed Query:iter_matches's
        -- `all = false` option per its 0.11 deprecation schedule. archived
        -- nvim-treesitter master query_predicates.lua line 19 still requests
        -- `{ all = false }`; the option is now silently ignored, so match[id]
        -- arrives as TSNode[] and `vim.treesitter.get_node_text(node)` crashes
        -- ("attempt to call method 'range' (a nil value)") under markdown
        -- injection — first LSP hover is the canonical trigger.
        --
        -- master was archived 42fc28b (Mar 2026), one day before the nvim
        -- removal. No upstream fix is coming. Cleanest exit is migrating to
        -- nvim-treesitter `main` branch (a multi-day port: master's
        -- `nvim-treesitter.configs.setup{}` API is gone, textobjects has a new
        -- per-feature API on its own `main` branch, and nvim-treesitter-context
        -- only ships `master`). Until then, re-register the four affected
        -- directives after plugin/nvim-treesitter.lua runs, normalising match[id]
        -- to a single node so handlers work under both legacy and modern formats.
        vim.api.nvim_create_autocmd("VimEnter", {
          group = vim.api.nvim_create_augroup("NvimSpineTreesitterPatch", { clear = true }),
          once = true,
          callback = function()
            local ok, query = pcall(require, "vim.treesitter.query")
            if not ok then return end

            ---@param match table
            ---@param id any
            ---@return TSNode|nil
            local function pick(match, id)
              local n = match[id]
              if type(n) == "table" then
                return n[#n]
              end
              return n
            end

            local html_script_type_languages = {
              ["importmap"] = "json",
              ["module"] = "javascript",
              ["application/ecmascript"] = "javascript",
              ["text/ecmascript"] = "javascript",
            }
            local non_filetype_match_injection_language_aliases = {
              ex = "elixir", pl = "perl", sh = "bash", uxn = "uxntal", ts = "typescript",
            }
            local function info_string_lang(alias)
              local m = vim.filetype.match { filename = "a." .. alias }
              return m or non_filetype_match_injection_language_aliases[alias] or alias
            end

            local opts = { force = true }

            query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
              local node = pick(match, pred[2])
              if not node then return end
              local alias = vim.treesitter.get_node_text(node, bufnr):lower()
              metadata["injection.language"] = info_string_lang(alias)
            end, opts)

            query.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
              local node = pick(match, pred[2])
              if not node then return end
              local val = vim.treesitter.get_node_text(node, bufnr)
              local configured = html_script_type_languages[val]
              if configured then
                metadata["injection.language"] = configured
              else
                local parts = vim.split(val, "/", {})
                metadata["injection.language"] = parts[#parts]
              end
            end, opts)

            query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
              local id = pred[2]
              local node = pick(match, id)
              if not node then return end
              local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ""
              if not metadata[id] then metadata[id] = {} end
              metadata[id].text = string.lower(text)
            end, opts)

            query.add_predicate("kind-eq?", function(match, _, _, pred)
              local node = pick(match, pred[2])
              if not node then return true end
              local types = { unpack(pred, 3) }
              return vim.tbl_contains(types, node:type())
            end, opts)
          end,
        })
      '';
    };
  };
}
