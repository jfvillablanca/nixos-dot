-- nvim-treesitter-textobjects setup. Path B: only `textobjects` is configured
-- here; highlight/indent/autopairs are NOT engaged via nvim-treesitter.configs
-- (highlight goes through vim.treesitter.start in the treesitter spine).
require("nvim-treesitter.configs").setup({
    textobjects = {
        select = {
            enable = true,
            lookahead = true,
            keymaps = {
                ["af"] = { query = "@function.outer", desc = "Select outer function" },
                ["if"] = { query = "@function.inner", desc = "Select inner function" },
                ["ac"] = { query = "@class.outer", desc = "Select outer class" },
                ["ic"] = { query = "@class.inner", desc = "Select inner class" },
                ["l="] = { query = "@assignment.lhs", desc = "Select assignment LHS" },
                ["r="] = { query = "@assignment.rhs", desc = "Select assignment RHS" },
                ["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
            },
            selection_modes = {
                ["@parameter.outer"] = "v",
                ["@function.outer"] = "V",
                ["@class.outer"] = "<c-v>",
            },
            include_surrounding_whitespace = true,
        },
    },
})
