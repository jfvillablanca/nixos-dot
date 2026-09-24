-- nvim-treesitter, wired against its `main` branch.
--
-- The old `require("nvim-treesitter.configs").setup { highlight = ..., indent
-- = ..., textobjects = ... }` module system no longer exists: `main` dropped
-- the `nvim-treesitter.configs` module entirely, so that call failed, its
-- `if not status_ok then return end` guard fired, and -- because home-manager
-- concatenates every plugin config into one init.lua chunk -- took the rest of
-- the file down with it. Each concern is now driven directly.
--
-- Two of the old keys are simply gone:
--   * `query_linter` was removed upstream (it was a query-authoring tool).
--   * `autopairs` was nvim-autopairs registering itself as a treesitter
--     module; it does its own detection now via `check_ts` (see autopairs.lua).
--
-- Parsers and queries come from nixpkgs (`nvim-treesitter.withAllGrammars`),
-- so there is nothing to install at runtime and no `ensure_installed` to set.

-- Highlighting. Neovim only starts treesitter on its own for the handful of
-- parsers it bundles (c, lua, markdown, query, vim, vimdoc); every other
-- language silently falls back to regex syntax without this.
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("treesitter-highlight", { clear = true }),
    desc = "Start treesitter highlighting wherever a parser exists",
    callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match)
        if not lang then
            return
        end
        -- start() throws for a language whose parser is missing, and 'filetype'
        -- values outnumber the grammars we ship, so this has to stay guarded.
        pcall(vim.treesitter.start, ev.buf, lang)
    end,
})

-- Indentation. python and css keep their built-in indentexpr: the treesitter
-- indent queries for both disagree with the languages' own conventions badly
-- enough to be worse than no treesitter at all. This mirrors the
-- `indent = { disable = { "python", "css" } }` of the old config.
local indent_blocklist = {
    python = true,
    css = true,
}

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("treesitter-indent", { clear = true }),
    desc = "Use treesitter indentation where a query exists and it behaves",
    callback = function(ev)
        if indent_blocklist[ev.match] then
            return
        end
        local lang = vim.treesitter.language.get_lang(ev.match)
        if lang and vim.treesitter.query.get(lang, "indents") then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end,
})

-- Text objects. The plugin still takes its behavioural options through
-- setup(), but no longer accepts keymaps -- those are ours to define now.
require("nvim-treesitter-textobjects").setup({
    select = {
        -- Jump forward to the textobject if the cursor is not already inside one,
        -- like targets.vim.
        lookahead = true,
        selection_modes = {
            ["@parameter.outer"] = "v", -- charwise
            ["@function.outer"] = "V", -- linewise
            ["@class.outer"] = "<c-v>", -- blockwise
        },
        -- Extend a textobject to the whitespace around it, so `af` behaves like
        -- the built-in `ap`.
        include_surrounding_whitespace = true,
    },
})

-- lhs -> { capture, query group, description }. The group is "textobjects"
-- unless the capture comes from another query file: `@local.scope` lives in
-- locals.scm, and it was spelled `@scope` under the old module system.
local textobjects = {
    ["af"] = { "@function.outer", "textobjects", "Select outer part of a function region" },
    ["if"] = { "@function.inner", "textobjects", "Select inner part of a function region" },
    ["ac"] = { "@class.outer", "textobjects", "Select outer part of a class region" },
    ["ic"] = { "@class.inner", "textobjects", "Select inner part of a class region" },
    ["l="] = { "@assignment.lhs", "textobjects", "Select left-hand side of an assignment" },
    ["r="] = { "@assignment.rhs", "textobjects", "Select right-hand side of an assignment" },
    ["as"] = { "@local.scope", "locals", "Select language scope" },
}

for lhs, spec in pairs(textobjects) do
    local capture, group, desc = spec[1], spec[2], spec[3]
    vim.keymap.set({ "x", "o" }, lhs, function()
        require("nvim-treesitter-textobjects.select").select_textobject(capture, group)
    end, { desc = desc })
end
