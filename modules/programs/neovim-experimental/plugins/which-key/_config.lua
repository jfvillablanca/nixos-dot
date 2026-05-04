-- which-key setup. The keymap registry lives in the spine; this module
-- renders the popup and declares group prefixes so the popup labels them.
local wk = require("which-key")

wk.setup({
    plugins = {
        marks = true,
        registers = true,
        spelling = {
            enabled = false,
            suggestions = 20,
        },
        presets = {
            operators = false,
            motions = true,
            text_objects = true,
            windows = true,
            nav = true,
            z = true,
            g = true,
        },
    },
    icons = {
        breadcrumb = "»",
        separator = "➜",
        group = "+",
    },
    layout = {
        height = { min = 4, max = 25 },
        width = { min = 20, max = 50 },
        spacing = 3,
        align = "left",
    },
    show_help = true,
})

-- Group prefixes for the keymaps registered via the keymap spine. Individual
-- keymaps' descriptions are auto-discovered from vim.keymap.set's `desc`.
wk.add({
    { "<leader>t", group = "telescope" },
    { "<leader>g", group = "git (fugitive)" },
    { "<leader>h", group = "git (hunks)" },
    { "<leader>x", group = "diag" },
    { "<leader>l", group = "lsp" },
    { "<leader>b", group = "debug" },
    { "<leader>m", group = "treesj" },
    { "<leader>fm", group = "fun (cellular-automaton)" },
})
